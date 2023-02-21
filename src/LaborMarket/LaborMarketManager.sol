// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { LaborMarketInterface } from "./interfaces/LaborMarketInterface.sol";
import { ERC1155HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import { Delegatable } from "delegatable/Delegatable.sol";

/// @dev Helper interfaces.
import { LaborMarketNetworkInterface } from "../Network/interfaces/LaborMarketNetworkInterface.sol";
import { EnforcementCriteriaInterface } from "../Modules/Enforcement/interfaces/EnforcementCriteriaInterface.sol";
import { ReputationModuleInterface } from "../Modules/Reputation/interfaces/ReputationModuleInterface.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Supported interfaces.
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";

contract LaborMarketManager is
    LaborMarketInterface,
    ERC1155HolderUpgradeable,
    Delegatable("LaborMarket", "v1.0.0")
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
          address indexed reviewer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 reviewScore
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
            configuration.owner == address(0) || 
            _msgSender() == configuration.owner || 
            _msgSender() == address(network),
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
     * @notice Gets the amount of pending rewards for a submission.
     * @param _submissionId The id of the service submission.
     * @return pTokenToClaim The amount of pTokens to be claimed.
     * @return rTokenToClaim The amount of rTokens to be claimed.
     */
    function getRewards(
        uint256 _submissionId
    )
        external
        view
        returns (
              uint256 pTokenToClaim
            , uint256 rTokenToClaim
        )
    {
        address provider = serviceSubmissions[_submissionId].serviceProvider;
        
        if (hasPerformed[_submissionId][provider][HAS_CLAIMED]) {
            return (0, 0);
        }

        return enforcementCriteria.getRewards(
              address(this)
            , _submissionId
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
                            INTERNAL SETTERS
    //////////////////////////////////////////////////////////////*/

    function _claim(
          uint256 _requestId
        , uint256 _submissionId
        , address _to
    )
        internal
        returns (
            uint256 pTokenClaimed,
            uint256 rTokenClaimed
        )
    {
        /// @dev Provider has claimed this submission.
        hasPerformed[_submissionId][_msgSender()][HAS_CLAIMED] = true;

        /// @dev Get the rewards.
        (pTokenClaimed, rTokenClaimed) = enforcementCriteria.getRewards(
            address(this),
            _submissionId
        );

        /// @dev Transfer the pTokens.
        IERC20(
            serviceRequests[_requestId].pToken
        ).transfer(
            _to,
           pTokenClaimed
        );

        /// @dev Mint the rToken reward.
        reputationModule.mintReputation(
            _msgSender(), 
            rTokenClaimed
        );

        emit RequestPayClaimed(_msgSender(), _requestId, _submissionId, pTokenClaimed, _to);
    }

    /**
     * @notice Allows a service provider to fulfill a service request.
     */
    function _provide(
          uint256 _requestId
        , string calldata _uri
    )
        internal
    {
         /// @dev Increment the submission count and service ID.
        unchecked {
            ++serviceId;
            ++serviceRequests[_requestId].submissionCount;
        }

        /// @dev Set the submission.
        serviceSubmissions[serviceId] = ServiceSubmission({
            serviceProvider: _msgSender(),
            requestId: _requestId,
            timestamp: block.timestamp,
            uri: _uri,
            reviewed: false
        });

        /// @dev Provider has submitted.
        hasPerformed[_requestId][_msgSender()][HAS_SUBMITTED] = true;

        /// @dev Use the user's reputation.
        reputationModule.mintReputation(_msgSender(), configuration.reputationParams.provideStake);

        emit RequestFulfilled(_msgSender(), _requestId, serviceId, _uri);
    }

    /**
     * @notice Facilitates the review of a service submission.
     */
    function _review(
          uint256 _requestId
        , uint256 _submissionId
        , uint256 _score
    )
        internal
    {
        /// @dev Set the submission's review state.
        if (!serviceSubmissions[_submissionId].reviewed)
            serviceSubmissions[_submissionId].reviewed = true;

        /// @dev Maintainer has reviewed this submission.
        hasPerformed[_submissionId][_msgSender()][HAS_REVIEWED] = true;

        /// @dev Review the submission.
        enforcementCriteria.review(_submissionId, _score);

        /// @dev Decrement the maintainer's review signal.
        unchecked {
            --reviewSignals[_requestId][_msgSender()].remainder;
        }

        /// @dev Use the maintainer's reputation.
        reputationModule.mintReputation(
            _msgSender(),
            configuration.reputationParams.reviewStake
        );

        emit RequestReviewed(_msgSender(), _requestId, _submissionId, _score);
    }

    /**
     * @notice Facilitates the state changing of a request.
     */
    function _setRequest(
          uint256 _serviceId
        , address _pToken
        , uint256 _pTokenQ
        , uint256 _signalExp
        , uint256 _submissionExp
        , uint256 _enforcementExp
        , string calldata _requestUri
    )
        internal
    {
        IERC20 pToken = IERC20(_pToken);

        /// @dev Keep accounting in mind for ERC20s with transfer fees.
        uint256 pTokenBefore = pToken.balanceOf(address(this));

        pToken.transferFrom(_msgSender(), address(this), _pTokenQ);

        uint256 pTokenAfter = pToken.balanceOf(address(this));

        serviceRequests[_serviceId] = ServiceRequest({
            serviceRequester: _msgSender(),
            pToken: _pToken,
            pTokenQ: (pTokenAfter - pTokenBefore),
            signalExp: _signalExp,
            submissionExp: _submissionExp,
            enforcementExp: _enforcementExp,
            submissionCount: 0,
            uri: _requestUri
        });

        emit RequestConfigured(
            _msgSender(),
            _serviceId,
            _requestUri,
            _pToken,
            _pTokenQ,
            _signalExp,
            _submissionExp,
            _enforcementExp
        );
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
    function _isValidTimestamps(
        uint256 _signalExp,
        uint256 _submissionExp,
        uint256 _enforcementExp
    )
        internal
        view
        returns (bool)
    {
        return (
            block.timestamp < _signalExp 
            && _signalExp < _submissionExp 
            && _submissionExp < _enforcementExp
        );
    }
}
