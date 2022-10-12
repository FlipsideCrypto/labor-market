// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MetricNetwork {
    uint256 public baseSignal;
    uint256 public baseParticipantReputation;
    uint256 public baseMaintainerReputation;

    constructor(uint256 baseSig, uint256 baseRep) {
        baseSignal = baseSig;
        baseParticipantReputation = baseRep;
        baseMaintainerReputation = baseRep * 10;
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
