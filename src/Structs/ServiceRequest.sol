// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO: pack

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
