// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Interfacing
import {MetricNetwork} from "./MetricNetwork.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";

// Structs
import {ServiceRequest} from "./Structs/ServiceRequest.sol";

// Events & Errors
import {LaborMarketEventsAndErrors} from "./EventsAndErrors/LaborMarketEventsAndErrors.sol";

contract LaborMarket is LaborMarketEventsAndErrors {
    MetricNetwork public metricNetwork;

    ERC1155 public delegateBadge;
    ERC1155 public participationBadge;

    uint256 public delegateTokenId;
    uint256 public participationTokenId;

    address public payCurve;
    address public enforcementCriteria;

    uint256 public repMultiplier;
    string public marketUri;
    uint256 public immutable marketId;

    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => mapping(address => bool)) public hasSignaled;
    mapping(uint256 => uint256) public signalCount;
    mapping(address => bool) public permissioned;

    uint256 public serviceRequestId;

    constructor(
        address _metricNetwork,
        address _delegateBadge,
        uint256 _delegateTokenId,
        address _participationBadge,
        uint256 _participationTokenId,
        address _payCurve,
        address _enforcementCriteria,
        uint256 _repMultiplier,
        string memory _marketUri,
        uint256 _marketId
    ) {
        metricNetwork = MetricNetwork(_metricNetwork);
        delegateBadge = ERC1155(_delegateBadge);
        delegateTokenId = _delegateTokenId;
        participationBadge = ERC1155(_participationBadge);
        participationTokenId = _participationTokenId;
        payCurve = _payCurve;
        enforcementCriteria = _enforcementCriteria;
        repMultiplier = _repMultiplier;
        marketUri = _marketUri;
        marketId = _marketId;
    }

    // Submit a service request
    function submitRequest(
        address pToken,
        uint256 pTokenId,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp,
        string calldata requestUri
    ) external returns (uint256 requestId) {
        unchecked {
            ++serviceRequestId;
        }

        ServiceRequest memory serviceRequest = ServiceRequest({
            serviceRequester: msg.sender,
            pToken: pToken,
            pTokenId: pTokenId,
            pTokenQ: pTokenQ,
            signalExp: signalExp,
            submissionExp: submissionExp,
            enforcementExp: enforcementExp,
            uri: requestUri
        });

        serviceRequests[serviceRequestId] = serviceRequest;

        emit RequestCreated(
            msg.sender,
            serviceRequestId,
            requestUri,
            pToken,
            pTokenId,
            pTokenQ,
            signalExp,
            submissionExp,
            enforcementExp
        );

        return serviceRequestId;
    }

    // Signal a service request
    function signal(uint256 requestId) external permittedParticipant {
        if (requestId > serviceRequestId) {
            revert RequestDoesNotExist(requestId);
        }
        if (block.timestamp > serviceRequests[requestId].signalExp) {
            revert SignalDeadlinePassed();
        }
        if (hasSignaled[requestId][msg.sender]) {
            revert AlreadySignaled();
        }

        uint256 signalAmt = _balanceReputation();
        hasSignaled[requestId][msg.sender] = true;

        unchecked {
            ++signalCount[requestId];
        }

        emit RequestSignal(msg.sender, requestId, signalAmt);
    }

    // Withdraw a service request given that it has not been signaled
    function withdrawRequest(uint256 requestId) external {
        if (serviceRequests[requestId].serviceRequester != msg.sender)
            revert NotTheRequester(msg.sender);
        if (signalCount[requestId] > 0) revert RequestActive(requestId);

        delete serviceRequests[requestId];

        emit RequestWithdrawn(requestId);
    }

    // Update market parameters as long as the market is not active
    function setMarketParameters(
        address _delegateBadge,
        address _participationBadge,
        address _payCurve,
        address _enforcementCriteria,
        uint256 _repMultiplier,
        string calldata _marketUri
    ) external {
        if (serviceRequestId > 0) revert MarketActive();
        delegateBadge = ERC1155(_delegateBadge);
        participationBadge = ERC1155(_participationBadge);
        payCurve = _payCurve;
        enforcementCriteria = _enforcementCriteria;
        repMultiplier = _repMultiplier;
        marketUri = _marketUri;

        emit MarketParametersUpdated(
            marketId,
            _delegateBadge,
            _participationBadge,
            _payCurve,
            _enforcementCriteria,
            _repMultiplier,
            _marketUri
        );
    }

    function _balanceReputation() internal returns (uint256) {
        uint256 signalAmt = metricNetwork.baseSignal();

        participationBadge.safeTransferFrom(
            msg.sender,
            address(this),
            participationTokenId,
            signalAmt,
            ""
        );

        return signalAmt;
    }

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory)
    {
        return serviceRequests[requestId];
    }

    modifier permittedParticipant() {
        if (
            (delegateBadge.balanceOf(msg.sender, delegateTokenId) < 1) ||
            (participationBadge.balanceOf(msg.sender, participationTokenId) <
                (metricNetwork.baseReputation() * repMultiplier))
        ) revert NotQualified();
        _;
    }
}
