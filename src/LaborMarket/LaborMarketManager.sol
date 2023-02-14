// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from "./interfaces/LaborMarketInterface.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { Delegatable, DelegatableCore } from "delegatable/Delegatable.sol";

/// @dev Helper interfaces.
import { LaborMarketNetworkInterface } from "../Network/interfaces/LaborMarketNetworkInterface.sol";
import { EnforcementCriteriaInterface } from "../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";
import { ReputationModuleInterface } from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Supported interfaces.
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { IERC721ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract LaborMarketManager is
    LaborMarketInterface,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    Delegatable("LaborMarket", "v1.0.0"),
    ContextUpgradeable
{
    /// @dev Performable actions.
    bytes32 internal constant HAS_SUBMITTED = keccak256("hasSubmitted");

    bytes32 internal constant HAS_CLAIMED = keccak256("hasClaimed");

    bytes32 internal constant HAS_CLAIMED_REMAINDER =
        keccak256("hasClaimedRemainder");

    bytes32 internal constant HAS_REVIEWED = keccak256("hasReviewed");
    
    bytes32 internal constant HAS_SIGNALED = keccak256("hasSignaled");

    /// @dev The network contract.
    LaborMarketNetworkInterface internal network;

    /// @dev The enforcement criteria.
    EnforcementCriteriaInterface internal enforcementCriteria;

    /// @dev The reputation module.
    ReputationModuleInterface internal reputationModule;

    /// @dev The delegate badge.
    IERC1155 internal delegateBadge;

    /// @dev The maintainer badge.
    IERC1155 internal maintainerBadge;

    /// @dev The configuration of the labor market.
    LaborMarketConfiguration public configuration;

    /// @dev Tracking the signals per service request.
    mapping(uint256 => uint256) public signalCount;

    /// @dev Tracking the service requests.
    mapping(uint256 => ServiceRequest) public serviceRequests;

    /// @dev Tracking the service submissions.
    mapping(uint256 => ServiceSubmission) public serviceSubmissions;

    /// @dev Tracking the review signals.
    mapping(uint256 => mapping(address => ReviewPromise)) public reviewSignals;

    /// @dev Tracking whether an action has been performed.
    mapping(uint256 => mapping(address => mapping(bytes32 => bool)))
        public hasPerformed;

    /// @dev The service request id counter.
    uint256 public serviceId;

    /// @notice emitted when labor market parameters are updated.
    event LaborMarketConfigured(
        LaborMarketConfiguration indexed configuration
    );

    /// @notice emitted when a new service request is made.
    event RequestConfigured(
          address indexed requester
        , uint256 indexed requestId
        , string indexed uri
        , address pToken
        , uint256 pTokenQ
        , uint256 signalExp
        , uint256 submissionExp
        , uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request.
    event RequestSignal(
          address indexed signaler
        , uint256 indexed requestId
        , uint256 indexed signalAmount
    );

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(
          address indexed signaler
        , uint256 indexed requestId
        , uint256 indexed quantity
        , uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(
        uint256 indexed requestId
    );

    /// @notice emitted when a service request is fulfilled.
    event RequestFulfilled(
          address indexed fulfiller
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , string uri
    );

    /// @notice emitted when a service submission is reviewed
    event RequestReviewed(
          address reviewer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 indexed reviewScore
    );

    /// @notice emitted when a service submission is claimed.
    event RequestPayClaimed(
          address indexed claimer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 payAmount
        , address to
    );

    /// @notice emitted when a remainder is claimed.
    event RemainderClaimed(
          address indexed claimer
        , uint256 indexed requestId
        , uint256 remainderAmount
    );

    /// @notice Gates the permissions to create new requests.
    modifier onlyDelegate() {
        require(
            address(delegateBadge) == address(0) ||
            delegateBadge.balanceOf(
                _msgSender(),
                configuration.delegateBadge.tokenId
            ) > 0,
            "LaborMarket::onlyDelegate: Not delegate"
        );
        _;
    }

    /// @notice Gates the permissions to review submissions.
    modifier onlyMaintainer() {
        require(
            maintainerBadge.balanceOf(
                _msgSender(),
                configuration.maintainerBadge.tokenId
            ) > 0,
            "LaborMarket::onlyMaintainer: Not maintainer"
        );
        _;
    }

    /// @notice Gates the permissions to provide submissions based on reputation.
    modifier permittedParticipant() {
        uint256 availableRep = reputationModule.getAvailableReputation(
            address(this),
            _msgSender()
        );

        require((
                availableRep >= configuration.reputationParams.submitMin &&
                availableRep < configuration.reputationParams.submitMax
            ), "LaborMarket::permittedParticipant: Not permitted participant"
        );
        _;
    }

    /// @notice Initialize the labor market.
    function initialize(
        LaborMarketConfiguration calldata _configuration
    )
        external
        override
        initializer
    {
        setConfiguration(_configuration);
    }

    /**
     * @notice Allows a network governor to set the configuration.
     * @param _configuration The new configuration.
     * Requirements:
     * - The caller must be the owner of the market or a 
     *   governor at the network level.
     */
    function setConfiguration(
        LaborMarketConfiguration calldata _configuration
    )
        public
    {
        require(
            configuration.owner == address(0) || _msgSender() == configuration.owner || _msgSender() == address(network),
            "LaborMarketManager::setConfiguration: Not owner or governor"
        );

        require(serviceId == 0, "LaborMarketManager::setConfiguration: Market in use");

        network = LaborMarketNetworkInterface(_configuration.modules.network);

        /// @dev Configure the Labor Market state control.
        enforcementCriteria = EnforcementCriteriaInterface(
            _configuration.modules.enforcement
        );

        /// @dev Configure the Labor Market reputation module.
        reputationModule = ReputationModuleInterface(
            _configuration.modules.reputation
        );

        /// @dev Configure the Labor Market access control.
        delegateBadge = IERC1155(_configuration.delegateBadge.token);
        maintainerBadge = IERC1155(_configuration.maintainerBadge.token);

        /// @dev Configure the Labor Market parameters.
        configuration = _configuration;

        emit LaborMarketConfigured(_configuration);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows a service provider to signal their intent to perform a service.
     * @param _submissionId The id of the service submission.
     * @param _data The data to be used in the enforcement criteria.
     */
    function getRewards(
          uint256 _submissionId
        , bytes calldata _data
    )
        external
        view
        returns (
              uint256 pTokenClaimed
            , uint256 rTokenClaimed
        )
    {
        address provider = serviceSubmissions[_submissionId].serviceProvider;
        
        if (hasPerformed[_submissionId][provider][HAS_CLAIMED]) {
            return (0, 0);
        }

        return enforcementCriteria.getRewards(
              address(this)
            , _submissionId
            , _data
        );
    }

    /**
     * @notice Returns the service request data.
     * @param _requestId The id of the service requesters request.
     */
    function getRequest(
        uint256 _requestId
    )
        external
        override
        view
        returns (ServiceRequest memory)
    {
        return serviceRequests[_requestId];
    }

    /**
     * @notice Returns the service submission data.
     * @param _submissionId The id of the service providers submission.
     */
    function getSubmission(
        uint256 _submissionId
    )
        external
        override
        view
        returns (ServiceSubmission memory)
    {
        return serviceSubmissions[_submissionId];
    }

    /**
     * @notice Returns the market configuration.
     */
    function getConfiguration()
        external
        override
        view
        returns (LaborMarketConfiguration memory)
    {
        return configuration;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Checks if the timestamps are valid.
     * @param _signalExp The expiration of the signal period.
     * @param _submissionExp The expiration of the submission period.
     * @param _enforcementExp The expiration of the enforcement period.
     */
    function _validateTimestamps(
        uint256 _signalExp,
        uint256 _submissionExp,
        uint256 _enforcementExp
    )
        internal
        view
    {
        require(
               block.timestamp < _signalExp 
            && _signalExp < _submissionExp 
            && _submissionExp < _enforcementExp,
            "LaborMarket::expirations: Invalid expirations"
        );
    }


    /**
     * @dev Delegatable ETH support
     */
    function _msgSender()
        internal
        view
        virtual
        override(DelegatableCore, ContextUpgradeable)
        returns (
            address sender
        )
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
