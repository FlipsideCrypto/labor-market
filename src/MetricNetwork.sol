// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { LaborMarketFactory } from "./LaborMarket/LaborMarketFactory.sol";

contract MetricNetwork is 
    LaborMarketFactory
{
    uint256 public baseSignal;
    uint256 public baseParticipantReputation;
    uint256 public baseMaintainerReputation;

    constructor(
          address _baseImplementation
        , uint256 _baseSig
        , uint256 _baseRep
    ) LaborMarketFactory(
        _baseImplementation
    ) {
        baseSignal = _baseSig;
        baseParticipantReputation = _baseRep;
        baseMaintainerReputation = _baseRep * 10;
    }

    // TODO: onlyGoverner
    // TODO: virtual rep management

    function setSignal(uint256 amount) external {
        baseSignal = amount;
    }

    function setParticipantRep(uint256 amount) external {
        baseParticipantReputation = amount;
    }

    function setMaintainerRep(uint256 amount) external {
        baseMaintainerReputation = amount;
    }
}
