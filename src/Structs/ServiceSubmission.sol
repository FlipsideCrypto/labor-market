// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// TODO: pack

struct ServiceSubmission {
    address serviceProvider;
    uint256 timestamp;
    string uri;
    uint256 score;
}
