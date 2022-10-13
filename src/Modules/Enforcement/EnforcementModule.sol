// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { EnforcementCriteriaInterface } from "./interfaces/EnforcementCriteriaInterface.sol";

contract EnforcementModule {
    // Review a submission and assign a score
    function review(
          address enforcementLogic
        , uint256 submissionId
        , uint256 score
    ) 
        public 
        returns (
            uint256
        ) 
    {
        return EnforcementCriteriaInterface(enforcementLogic).review(
              submissionId
            , score
        );
    }

    // Calculate the index based on the scored submission
    function verifyIndex(
          address enforcementLogic
        , uint256 submissionId
    )
        public
        returns (
            uint256
        )
    {
        return EnforcementCriteriaInterface(enforcementLogic).verify(submissionId);
    }
}
