// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {PayCurveInterface} from "src/Modules/Payment/interfaces/PayCurveInterface.sol";

contract FCFSEnforcementCriteria {
    /// @dev First come first servce on linear decreasing payout curve
    /// @dev First 100 submissions that are marked as good get paid

    mapping(address => mapping(uint256 => uint256)) public submissionToIndex;

    /// @dev Max number of submissions that can be paid out
    uint256 public constant MAX_SCORE = 10;

    /// @dev Tracks the number of submissions per requestId that have been paid out
    mapping(uint256 => uint256) public payCount;

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows maintainer to review with either 0 (bad) or 1 (good)
     * @param submissionId The submission to review
     * @param score The score to give the submission
     */
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        uint256 requestId = getRid(submissionId);

        require(score <= 1, "EnforcementCriteria::review: invalid score");

        if (score > 0 && payCount[requestId] < MAX_SCORE) {
            submissionToIndex[msg.sender][submissionId] = payCount[requestId];

            unchecked {
                payCount[requestId]++;
            }
        }

        return score;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets the curve index of a submission
    function verify(uint256 submissionId) external view returns (uint256) {
        return submissionToIndex[msg.sender][submissionId];
    }

    /// @dev Returns the remainder that is claimable by the requester of a requestId
    function getRemainder(uint256 requestId) public returns (uint256) {
        if (payCount[requestId] >= MAX_SCORE) {
            return 0;
        } else {
            uint256 claimable;
            LaborMarketInterface market = LaborMarketInterface(msg.sender);
            PayCurveInterface curve = PayCurveInterface(
                market.getConfiguration().modules.payment
            );
            for (uint256 i; i < (MAX_SCORE - payCount[requestId]); i++) {
                uint256 index = (payCount[requestId] + i);
                claimable += curve.curvePoint(index);
            }
            return claimable;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }
}
