// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ReputationTokenInterface {
    struct ReputationAccountInfo {
        uint256 locked;
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function initialize(
          address _module
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    )
        external;

    function setDecayConfig(
        uint256 _decayRate,
        uint256 _decayInterval
    ) 
        external;

    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        external;


    function lockReputation(
        address _account,
        uint256 _amount
    ) 
        external;

    function unlockReputation(
        address _account,
        uint256 _amount
    ) 
        external;

    function getAvailableReputation(address _account)
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(address _account)
        external
        view
        returns (
            uint256
        );

    function getReputationAccountInfo(address _account)
        external
        view
        returns (
            ReputationTokenInterface.ReputationAccountInfo memory
        );
}