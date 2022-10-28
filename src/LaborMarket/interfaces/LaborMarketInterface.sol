// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {LaborMarketConfigurationInterface} from "./LaborMarketConfigurationInterface.sol";

interface LaborMarketInterface is LaborMarketConfigurationInterface {
    struct ServiceRequest {
        address serviceRequester;
        address pToken;
        uint256 pTokenId;
        uint256 pTokenQ;
        uint256 signalExp;
        uint256 submissionExp;
        uint256 enforcementExp;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
        uint256 timestamp;
        string uri;
        uint256 score;
        bool graded;
    }

    function initialize(
        LaborMarketConfiguration calldata _configuration
    ) external;

    function getSubmission(uint256 submissionId)
        external
        view
        returns (ServiceSubmission memory);

    function getRequest(uint256 requestId)
        external
        view
        returns (ServiceRequest memory);
}
