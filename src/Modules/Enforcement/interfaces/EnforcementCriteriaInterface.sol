// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface EnforcementCriteriaInterface {
    function review(
          uint256 _submissionId
        , uint256 _score
    )
        external
        returns (
            uint256
        );

    function getShareOfPool(
        uint256 _submissionId
    ) 
        external 
        view
        returns (
            uint256
        );

    function getShareOfPoolWithData(
          uint256 _submissionId
        , bytes calldata _data
    )
        external
        view
        returns (
            uint256
        );

    function getRemainder(
        uint256 _requestId
    ) 
        external 
        view 
        returns (
            uint256
        );
}