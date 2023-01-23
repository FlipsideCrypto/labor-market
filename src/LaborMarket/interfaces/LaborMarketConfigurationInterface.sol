// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

// import { ReputationModuleInterface } from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

interface LaborMarketConfigurationInterface {
    struct LaborMarketConfiguration {
        string marketUri;
        Modules modules;
        BadgePair delegate;
        BadgePair maintainer;
        BadgePair reputation;
        uint256 signalStake;
        uint256 submitMin;
        uint256 submitMax;
    }

    struct BadgePair {
        address token;
        uint256 tokenId;
    }

    struct Modules {
        address network;
        address enforcement;
        address payment;
        address reputation;
    }
}