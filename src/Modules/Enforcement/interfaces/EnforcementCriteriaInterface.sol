// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface EnforcementCriteriaInterface {
    function review(uint256 submissionId, uint256 score)
        external
        returns (uint256);

    function verify(uint256 submissionId) external returns (uint256);

    function verifyWithData(uint256 submissionId, bytes calldata data)
        external
        returns (uint256);

    function getRemainder(uint256 requestId) external view returns (uint256);
}
