// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MetricNetwork {
    uint256 public baseSignal;
    uint256 public baseReputation;

    constructor(uint256 baseSig, uint256 baseRep) {
        baseSignal = baseSig;
        baseReputation = baseRep;
    }

    // TODO: onlyGoverner

    function setSignal(uint256 amount) external {
        baseSignal = amount;
    }

    function setRep(uint256 amount) external {
        baseReputation = amount;
    }
}
