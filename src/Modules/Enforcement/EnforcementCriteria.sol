// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO: look into https://github.com/paulrberg/prb-math
import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {console} from "forge-std/console.sol";

contract EnforcementCriteria {
    mapping(address => mapping(uint256 => Scores)) private submissionToScores;
    mapping(address => mapping(Likert => uint256)) private bucketCount;

    enum Likert {
        BAD,
        OK,
        GOOD
    }

    struct Scores {
        uint256[] scores;
        uint256 avg;
    }

    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        require(
            score <= uint256(Likert.GOOD),
            "EnforcementCriteria::review: invalid score"
        );

        // Update the bucket count for old score
        if (submissionToScores[msg.sender][submissionId].scores.length != 0) {
            unchecked {
                --bucketCount[msg.sender][
                    Likert(submissionToScores[msg.sender][submissionId].avg)
                ];
            }
        }

        // Add the new score
        submissionToScores[msg.sender][submissionId].scores.push(score);

        // Calculate the average
        submissionToScores[msg.sender][submissionId].avg = _getAvg(
            submissionToScores[msg.sender][submissionId].scores
        );

        // Update the bucket count for new score
        unchecked {
            ++bucketCount[msg.sender][
                Likert(submissionToScores[msg.sender][submissionId].avg)
            ];
        }

        return uint256(Likert(score));
    }

    function verify(uint256 submissionId) external view returns (uint256) {
        uint256 x;
        uint256 score = submissionToScores[msg.sender][submissionId].avg;

        uint256 alloc = (1e18 / getTotalBucket(msg.sender, Likert(score)));

        LaborMarketInterface market = LaborMarketInterface(msg.sender);
        uint256 pTokens = market
            .getRequest(market.getSubmission(submissionId).requestId)
            .pTokenQ / 1e18;

        if (score == uint256(Likert.BAD)) {
            x = sqrt(alloc * (pTokens * 0));
        } else if (score == uint256(Likert.OK)) {
            x = sqrt(alloc * ((pTokens * 20) / 100));
        } else if (score == uint256(Likert.GOOD)) {
            x = sqrt(alloc * ((pTokens * 80) / 100));
        }

        return x;
    }

    function getTotalBucket(address market, Likert score)
        internal
        view
        returns (uint256)
    {
        return bucketCount[market][score];
    }

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        // Stolen from prbmath
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x4) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }

    function _getAvg(uint256[] memory scores) internal pure returns (uint256) {
        uint256 cumScore;
        uint256 qScores = scores.length;

        for (uint256 i; i < qScores; ++i) {
            cumScore += scores[i];
        }

        return cumScore / qScores;
    }
}
