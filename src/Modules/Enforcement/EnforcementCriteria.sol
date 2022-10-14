// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO: look into https://github.com/paulrberg/prb-math

contract EnforcementCriteria {
    mapping(address => mapping(uint256 => uint256)) private submissionToScore;
    mapping(address => mapping(Likert => uint256)) private bucketCount;

    enum Likert {
        BAD,
        OK,
        GOOD
    }

    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256)
    {
        if (score > uint256(Likert.GOOD)) revert invalidScore();
        // Do stuff
        unchecked {
            ++bucketCount[msg.sender][Likert(score)];
        }

        submissionToScore[msg.sender][submissionId] = score;

        return uint256(Likert(score));
    }

    function verify(uint256 submissionId) external view returns (uint256) {
        uint256 score = submissionToScore[msg.sender][submissionId];
        uint256 alloc = (1e18 / getTotalBucket(msg.sender, Likert(score)));

        uint256 x;

        if (score == uint256(Likert.BAD)) {
            x = sqrt(alloc * (0 * 1000));
        } else if (score == uint256(Likert.OK)) {
            x = sqrt(alloc * (0.2 * 1000));
        } else if (score == uint256(Likert.GOOD)) {
            x = sqrt(alloc * (0.8 * 1000));
        }

        return x;
    }

    error invalidScore();

    function getTotalBucket(address market, Likert score)
        public
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
}
