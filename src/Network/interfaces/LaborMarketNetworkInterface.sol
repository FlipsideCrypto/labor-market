// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface LaborMarketNetworkInterface {
    struct BalanceInfo {
        uint256 locked;
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function setReputationImplementation(
        address _reputationImplementation
    )
        external;

    function setCapacityImplementation(
        address _capacityImplementation
    )
        external;

    function setReputationTokenId(
        uint256 _reputationTokenId
    )
        external;

    function setBaseSignalStake(
        uint256 _amount
    ) 
        external;

    function setBaseProviderThreshold(
        uint256 _amount
    ) 
        external;

    function setBaseMaintainerThreshold(
        uint256 _amount
    ) 
        external;

    function getAvailableReputation(address _account)
        external
        view
        returns (
            uint256
        );

    function freezeReputation(
        uint256 _frozenUntilEpoch
    ) 
        external;

    function getPendingDecay(
        uint256 _lastDecayEpoch,
        uint256 _frozenUntilEpoch
    )
        external 
        view 
        returns (
            uint256
        );

    function lockReputation(
          address user
        , uint256 amount
    ) 
        external;
}
