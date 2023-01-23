// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {PaymentToken} from "test/forge/Helpers/HelperTokens.sol";

import { BadgerOrganization } from "src/Modules/Badger/BadgerOrganization.sol";
import { Badger } from "src/Modules/Badger/Badger.sol";
import { BadgerScoutInterface } from "src/Modules/Badger/interfaces/BadgerScoutInterface.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import {LikertEnforcementCriteria} from "src/Modules/Enforcement/LikertEnforcementCriteria.sol";

import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

// Assumes:
// RPC_URL= ABC
// PRIVATE_KEY= DEF
// ETHERSCAN_API_KEY= GHI

struct PaymentTokenInt { 
    bytes32 paymentKey;
    uint256 amount;
}

contract X is Script {
    PaymentToken public payToken;
    
    BadgerOrganization public repToken;
    Badger public badger;
    BadgerOrganization public badgerMaster;

    LaborMarket public marketImplementation;
    LaborMarket public market;

    ReputationModule public reputationModule;

    LaborMarketNetwork public network;

    LikertEnforcementCriteria public enforcementCriteria;
    PayCurve public payCurve;

    // Define the tokenIds for ERC1155
    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;
    uint256 private constant MAINTAINER_TOKEN_ID = 3;
    uint256 private constant GOVERNOR_TOKEN_ID = 4;
    uint256 private constant REPUTATION_DECAY_RATE = 0;
    uint256 private constant REPUTATION_DECAY_INTERVAL = 0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Create a p token
        payToken = new PaymentToken(0x0F7494eE0831529fD676ADbc234f858e280AeAF0);

        // Create badger factory
        badgerMaster = new BadgerOrganization();
        badger = new Badger(address(badgerMaster));

        // Create reputation and role token contract
        repToken = BadgerOrganization(
            payable(badger.createOrganization(
                address(badgerMaster),
                address(this),
                "ipfs://000",
                "ipfs://000",
                "MDAO",
                "MDAO"
            )
        ));

        // Initialize reputation and roles
        address[] memory delegates;
        delegates[0] = address(this);
        for (uint256 i=0; i < GOVERNOR_TOKEN_ID; i++) {
            repToken.setBadge(
                i,
                false,
                true,
                address(this),
                "ipfs/",
                BadgerScoutInterface.PaymentToken({
                    paymentKey: bytes32(0),
                    amount: 0
                }),
                delegates
            );
        }

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(payToken),
            _governorBadge: address(repToken),
            _governorTokenId: GOVERNOR_TOKEN_ID
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Create enforcement criteria
        enforcementCriteria = new LikertEnforcementCriteria();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Reputation config
        ReputationModuleInterface.MarketReputationConfig
            memory repConfig = ReputationModuleInterface
                .MarketReputationConfig({
                    reputationToken: address(repToken),
                    reputationTokenId: REPUTATION_TOKEN_ID
                });

        // Create a new labor market configuration
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    marketUri: "ipfs://000",
                    modules: LaborMarketConfigurationInterface.Modules({
                        network: address(network),
                        reputation: address(reputationModule),
                        enforcement: address(enforcementCriteria),
                        payment: address(payCurve)
                    }),
                    delegate: LaborMarketConfigurationInterface.BadgePair(address(repToken), DELEGATE_TOKEN_ID),
                    maintainer: LaborMarketConfigurationInterface.BadgePair(address(repToken), MAINTAINER_TOKEN_ID),
                    reputation: LaborMarketConfigurationInterface.BadgePair(address(repToken), REPUTATION_TOKEN_ID),
                    signalStake: 1e18,
                    submitMin: 1e18,
                    submitMax: 100000e18
                });

        // Create a new labor market
        market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: msg.sender,
                _marketConfiguration: config
            })
        );

        vm.stopBroadcast();
    }
}
