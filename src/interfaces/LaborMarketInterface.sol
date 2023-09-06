// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Helper interfaces.
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { EnforcementCriteriaInterface } from './enforcement/EnforcementCriteriaInterface.sol';
import { NBadgeAuthInterface } from './auth/NBadgeAuthInterface.sol';

interface LaborMarketInterface {
    /// @notice Schema definition of a Request.
    struct ServiceRequest {
        uint48 signalExp;
        uint48 submissionExp;
        uint48 enforcementExp;
        uint64 providerLimit;
        uint64 reviewerLimit;
        uint256 pTokenProviderTotal;
        uint256 pTokenReviewerTotal;
        IERC20 pTokenProvider;
        IERC20 pTokenReviewer;
    }

    /// @notice Schema definition of the state a Request may be in.
    /// @dev Used to track signal:attendance rates.
    struct ServiceSignalState {
        uint64 providers;
        uint64 reviewers;
        uint64 reviewersArrived;
    }

    /// @notice Emitted when labor market parameters are updated.
    event LaborMarketConfigured(address deployer, string uri, address criteria);

    /// @notice Announces when a new Request has been configured inside a Labor Market.
    event RequestConfigured(
        address indexed requester,
        uint256 indexed requestId,
        uint48 signalExp,
        uint48 submissionExp,
        uint48 enforcementExp,
        uint64 providerLimit,
        uint64 reviewerLimit,
        uint256 pTokenProviderTotal,
        uint256 pTokenReviewerTotal,
        IERC20 pTokenProvider,
        IERC20 pTokenReviewer,
        string uri
    );

    /// @notice Announces when a Request has been signaled by a Provider.
    event RequestSignal(address indexed signaler, uint256 indexed requestId);

    /// @notice Announces when a Reviewer signals interest in reviewing a Request.
    event ReviewSignal(address indexed signaler, uint256 indexed requestId, uint256 indexed quantity);

    /// @notice Announces when a Request has been fulfilled by a Provider.
    event RequestFulfilled(
        address indexed fulfiller,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        string uri
    );

    /// @notice Announces when a Submission for a Request has been reviewed.
    event RequestReviewed(
        address indexed reviewer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 reviewId,
        uint256 reviewScore,
        string uri
    );

    /// @notice Announces when a Provider has claimed earnings for a Submission.
    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 payAmount,
        address to
    );

    /// @notice Announces the status of the remaining balance of a Request.
    event RemainderClaimed(address claimer, uint256 indexed requestId, address indexed to, bool indexed settled);

    /// @notice Announces when a Request has been withdrawn (cancelled) by the Requester.
    event RequestWithdrawn(uint256 indexed requestId);

    /**
     * @notice Initializes the newly deployed Labor Market contract.
     * @dev An initializer can only be called once and will throw if called twice in place of the constructor.
     * @param _deployer The address of the deployer.
     * @param _uri The internet-accessible uri of the Labor Market.
     * @param _criteria The enforcement criteria module used for this Labor Market.
     * @param _auxilaries The auxiliary values for the ennforcement criteria that is being used.
     * @param _alphas The alpha values for the enforcement criteria that is being used.
     * @param _betas The beta values for the enforcement criteria that is being used.
     * @param _sigs The signatures of the functions with permission gating.
     * @param _nodes The node definitions that are allowed to perform the functions with permission gating.
     */
    function initialize(
        address _deployer,
        string calldata _uri,
        EnforcementCriteriaInterface _criteria,
        uint256[] calldata _auxilaries,
        uint256[] calldata _alphas,
        uint256[] calldata _betas,
        bytes4[] calldata _sigs,
        NBadgeAuthInterface.Node[] calldata _nodes
    ) external;

    /**
     * @notice Submit a new Request to a Marketplace.
     * @param _request The Request being submit for work in the Labor Market.
     * @param _uri The internet-accessible URI of the Request.
     * @return requestId The id of the Request established onchain.
     */
    function submitRequest(
        uint8 _blockNonce,
        ServiceRequest calldata _request,
        string calldata _uri
    ) external returns (uint256 requestId);

    /**
     * @notice Signals interest in fulfilling a service Request.
     * @param _requestId The id of the Request the caller is signaling intent for.
     */
    function signal(uint256 _requestId) external;

    /**
     * @notice Signals interest in reviewing a Submission.
     * @param _requestId The id of the Request a Reviewer would like to assist in maintaining.
     * @param _quantity The amount of Submissions a Reviewer has intent to manage.
     */
    function signalReview(uint256 _requestId, uint24 _quantity) external;

    /**
     * @notice Allows a Provider to fulfill a Request.
     * @param _requestId The id of the Request being fulfilled.
     * @param _uri The internet-accessible uri of the Submission data.
     * @return submissionId The id of the Submission for the respective Request.
     */
    function provide(uint256 _requestId, string calldata _uri) external returns (uint256 submissionId);

    /**
     * @notice Allows a maintainer to participate in grading a Submission.
     * @param _requestId The id of the Request being fulfilled.
     * @param _submissionId The id of the Submission.
     * @param _score The score of the Submission.
     */
    function review(
        uint256 _requestId,
        uint256 _submissionId,
        uint256 _score,
        string calldata _uri
    ) external;

    /**
     * @notice Allows a Provider to claim earnings for a Request Submission after enforcement.
     * @dev When you want to determine what the earned amount is, you can use this
     *      function with a static call to determine the qausi-state of claiming.
     * @param _requestId The id of the Request being fulfilled.
     * @param _submissionId The id of the Submission.
     * @return success Whether or not the claim was successful.
     * @return amount The amount of tokens earned by the Submission.
     */
    function claim(uint256 _requestId, uint256 _submissionId) external returns (bool success, uint256 amount);

    /**
     * @notice Allows a Requester to claim the remainder of funds not allocated to participants.
     * @dev This model has been implemented to allow for bulk distribution of unclaimed rewards to
     *      assist in keeping the economy as healthy as possible.
     * @param _requestId The id of the Request.
     */
    function claimRemainder(uint256 _requestId)
        external
        returns (
            bool pTokenProviderSuccess,
            bool pTokenReviewerSuccess,
            uint256 pTokenProviderSurplus,
            uint256 pTokenReviewerSurplus
        );

    /**
     * @notice Allows a Requester to withdraw a Request and refund the pToken.
     * @param _requestId The id of the Request being withdrawn.
     */
    function withdrawRequest(uint256 _requestId) external;
}
