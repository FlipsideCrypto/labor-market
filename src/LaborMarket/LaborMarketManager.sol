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
    bytes32 public immutable HAS_SUBMITTED = keccak256("hasSubmitted");

    bytes32 public immutable HAS_CLAIMED = keccak256("hasClaimed");

    bytes32 public immutable HAS_CLAIMED_REMAINDER =
        keccak256("hasClaimedRemainder");

    bytes32 public immutable HAS_REVIEWED = keccak256("hasReviewed");
    
    bytes32 public immutable HAS_SIGNALED = keccak256("hasSignaled");

    /*//////////////////////////////////////////////////////////////
                            STATE
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Prevent implementation from being initialized.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the labor market.
    function initialize(
        LaborMarketConfiguration calldata _configuration
    )
        external
        override
        initializer
    {
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
        
        /// @dev The provider must have not claimed rewards.
        if (hasPerformed[_submissionId][provider][HAS_CLAIMED]) {
            return (0, 0);
        }

        return enforcementCriteria.getRewards(
              address(this)
            , _submissionId
        );
    }

    /// @notice Gets the delegate eligibility of a caller.
    /// @param _account The account to check.
    /// @return Whether the account is a delegate.
    function isDelegate(address _account) 
        public 
        view 
        returns (
            bool
        ) 
    {
        return (
            address(delegateBadge) == address(0) ||
            delegateBadge.balanceOf(_account, configuration.delegateBadge.tokenId) > 0
        );
    }

    /// @notice Gets the maintainer eligibility of a caller.
    /// @param _account The account to check.
    /// @return Whether the account is a maintainer.
    function isMaintainer(address _account) 
        public 
        view 
        returns (
            bool
        ) 
    {
        return (
            address(maintainerBadge) == address(0) ||
            maintainerBadge.balanceOf(_account, configuration.maintainerBadge.tokenId) > 0
        );
    }

    /// @notice Gets the eligibility of a caller to submit a service request.
    /// @param _account The account to check.
    /// @return Whether the account is eligible to submit a service request.
    function isPermittedParticipant(address _account)
        public
        view
        returns (
            bool
        )
    {
        uint256 availableRep = reputationModule.getAvailableReputation(
            address(this),
            _account
        );

        return (
            availableRep >= configuration.reputationParams.submitMin &&
            availableRep <= configuration.reputationParams.submitMax
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

        /// @dev Transfer the pTokens to the contract.
        pToken.transferFrom(_msgSender(), address(this), _pTokenQ);

        /// @dev Get the pToken balance after the transfer.
        uint256 pTokenAfter = pToken.balanceOf(address(this));

        /// @dev Set the service request.
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
