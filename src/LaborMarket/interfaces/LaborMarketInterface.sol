// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface LaborMarketInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        address owner;
        Modules modules;
    }

    struct Modules {
        address network;
        address enforcement;
        bytes32 enforcementKey;
    }

    struct ServiceRequest {
        address serviceRequester;
        IERC20 pToken;
        uint48 signalExp;
        uint48 submissionExp;
        uint48 enforcementExp;
        uint48 submissionCount;
        uint256 pTokenQ;
        string uri;
    }

    struct ServiceSubmission {
        address serviceProvider;
        uint256 requestId;
    }

    function initialize(LaborMarketConfiguration calldata _configuration)
        external;
}
