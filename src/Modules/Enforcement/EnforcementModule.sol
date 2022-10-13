// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IEnforcementCriteria} from "./Interfaces/IEnforcementCriteria.sol";

contract EnforcementModule {
    // Review a submission and assign a score
    function review(
        address enforcementLogic,
        uint256 submissionId,
        uint256 score
    ) public returns (uint256) {
        return
            IEnforcementCriteria(enforcementLogic).review(submissionId, score);
    }

    // Calculate the index based on the scored submission
    function verifyIndex(address enforcementLogic, uint256 submissionId)
        public
        returns (uint256)
    {
        return IEnforcementCriteria(enforcementLogic).verify(submissionId);
    }
}
