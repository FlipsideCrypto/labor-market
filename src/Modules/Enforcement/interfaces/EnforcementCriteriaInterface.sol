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

    function getRewards(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        view
        returns (
            uint256,
            uint256
        );

    function getPaymentReward(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        view
        returns (
            uint256
        );

    function getReputationReward(
          address _laborMarket
        , uint256 _submissionId
    )
        external
        view
        returns (
            uint256
        );

    function getRemainder(
          address _laborMarket
        , uint256 _requestId
    ) 
        external 
        view 
        returns (
            uint256
        );
}