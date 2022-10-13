// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface LaborMarketInterface {
    function initialize(
          address _metricNetwork
        , address _enforcementModule
        , address _paymentModule
        , address _delegateBadge
        , uint256 _delegateTokenId
        , address _participationBadge
        , uint256 _participationTokenId
        , uint256 _repParticipantMultiplier
        , uint256 _repMaintainerMultiplier
        , string memory _marketUri
    )
        external;
}