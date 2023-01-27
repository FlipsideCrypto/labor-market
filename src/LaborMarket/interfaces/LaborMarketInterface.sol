// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { LaborMarketConfigurationInterface } from "./LaborMarketConfigurationInterface.sol";

interface LaborMarketInterface is LaborMarketConfigurationInterface {
    struct ServiceRequest {
        address serviceRequester;
        address pToken;
        uint256 pTokenQ;
        uint256 signalExp;
        uint256 submissionExp;
        uint256 enforcementExp;
        uint256 submissionCount;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
        uint256 timestamp;
        string uri;
        uint256[] scores;
        bool reviewed;
    }

    struct ReviewPromise {
        uint256 total;
        uint256 remainder;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external;

    function setConfiguration(LaborMarketConfiguration calldata _configuration)
        external;

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory);

    function getConfiguration()
        external
        view
        returns (LaborMarketConfiguration memory);
}
