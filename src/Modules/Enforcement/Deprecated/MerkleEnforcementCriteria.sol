// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {PayCurveInterface} from "src/Modules/Payment/interfaces/PayCurveInterface.sol";

contract MerkleEnforcementCriteria is Ownable {
    /// @dev Merkle verification of submissions
    mapping(uint256 => bytes32) public requestToMerkleRoot;

    /// @dev Track indexes of submissions
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public requestToSubmissionToIndex;

    function setRoot(uint256 requestId, bytes32 merkleRoot) public onlyOwner {
        requestToMerkleRoot[requestId] = merkleRoot;
    }

    /**
     * @param submissionId The submission to review
     * @param index The index to give the submission
     */
    function review(uint256 submissionId, uint256 index)
        external
        returns (uint256)
    {
        uint256 requestId = getRid(submissionId);

        requestToSubmissionToIndex[msg.sender][requestId][submissionId] = index;

        return index;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Gets the curve index of a submission
    /// @dev requires that the submission is in the merkle tree
    function verifyWithData(uint256 submissionId, bytes calldata data)
        external
        view
        returns (uint256)
    {
        uint256 qProofs = data.length / 32;
        bytes32[] memory proofs = new bytes32[](qProofs);

        uint256 requestId = getRid(submissionId);

        assembly {
            // Free memory pointer
            let mptr := mload(0x40)

            // Calldatasize
            let size := calldatasize()

            // Copy relevant calldata to memory
            calldatacopy(mptr, 0x64, size)

            // Start at 0
            let i := 0

            // First element of array at 0x20
            let index := 0x20

            // Empty proof
            let proof := 0x00

            for {

            } lt(mul(i, 0x20), sub(size, 0x64)) {

            } {
                // Fetch proof
                proof := mload(add(mptr, mul(i, 0x20)))

                // Store proof at index in memory
                mstore(add(proofs, index), proof)

                // Increase loop
                i := add(i, 1)
                index := add(index, 0x20)
            }
        }

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(submissionId, msg.sender)))
        );

        bool ok = MerkleProof.verify({
            proof: proofs,
            root: requestToMerkleRoot[requestId],
            leaf: leaf
        });

        require(ok, "EnforcementCriteria::verifyWithData: invalid proof");

        return requestToSubmissionToIndex[msg.sender][requestId][submissionId];
    }

    /// @dev Gets a users requestId from submissionId
    function getRid(uint256 submissionId) internal view returns (uint256) {
        return
            LaborMarketInterface(msg.sender)
                .getSubmission(submissionId)
                .requestId;
    }
}
