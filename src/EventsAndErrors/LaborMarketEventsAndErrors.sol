// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract LaborMarketEventsAndErrors {
    /// @dev LaborMarket Events and Errors

    /// @notice emitted when a new labor market is created
    event LaborMarketCreated(
        uint256 indexed marketId,
        address delegateBadge,
        address participationBadge,
        address payCurve,
        address enforcementCriteria,
        uint256 repMultiplier,
        string marketUri
    );

    /// @notice emitted when labor market parameters are updated
    event MarketParametersUpdated(
        uint256 indexed marketId,
        address delegateBadge,
        address participationBadge,
        address payCurve,
        address enforcementCriteria,
        uint256 repMultiplier,
        string marketUri
    );

    /// @notice emitted when a new service request is made
    event RequestCreated(
        address indexed requester,
        uint256 indexed requestId,
        string indexed uri,
        address pToken,
        uint256 pTokenId,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request
    event RequestSignal(
        address indexed signaler,
        uint256 indexed requestId,
        uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn
    event RequestWithdrawn(uint256 indexed requestId);

    /// @notice thrown if a market is active
    error MarketActive();

    /// @notice thrown if anyone but the requester withdraws a request
    error NotTheRequester(address invalidRequester);

    /// @notice thrown if a request is already active
    error RequestActive(uint256 requestId);

    /// @notice thrown if a requestId does not exist
    error RequestDoesNotExist(uint256 requestId);

    /// @notice thrown if a user tries to signal twice
    error AlreadySignaled();

    /// @notice thrown if user tries to signal after deadline
    error SignalDeadlinePassed();

    /// @notice thrown if user does not meet requirements
    error NotQualified();
}
