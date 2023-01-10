// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {AnyReputationToken, PaymentToken} from "test/forge/Helpers/HelperTokens.sol";

import {ReputationEngineInterface} from "src/Modules/Reputation/interfaces/ReputationEngineInterface.sol";
import {ReputationEngine} from "src/Modules/Reputation/ReputationEngine.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import {LikertEnforcementCriteria} from "src/Modules/Enforcement/LikertEnforcementCriteria.sol";

import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

// Assumes:
// RPC_URL= ABC
// PRIVATE_KEY= DEF
// ETHERSCAN_API_KEY= GHI

contract X is Script {
    AnyReputationToken public repToken;
    PaymentToken public payToken;

    LaborMarket public marketImplementation;
    LaborMarket public market;

    ReputationEngine public reputationEngineMaster;
    ReputationEngine public reputationEngine;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    LikertEnforcementCriteria public enforcementCriteria;
    PaymentModule public paymentModule;
    PayCurve public payCurve;

    // Define the tokenIds for ERC1155
    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 0;
    uint256 private constant PAYMENT_TOKEN_ID = 0;
    uint256 private constant MAINTAINER_TOKEN_ID = 0;
    uint256 private constant REPUTATION_DECAY_RATE = 0;
    uint256 private constant REPUTATION_DECAY_INTERVAL = 0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Create a p token
        payToken = new PaymentToken(address(0xEd));

        // Generic reputation token
        repToken = new AnyReputationToken("Mock reputation", address(0xEd));

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy reputation token implementation
        reputationEngineMaster = new ReputationEngine();

        // Deploy a labor market factory
        factory = new LaborMarketFactory(address(marketImplementation));

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(address(0))
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Create enforcement criteria
        enforcementCriteria = new LikertEnforcementCriteria();

        // Create a payment module
        paymentModule = new PaymentModule();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Create a reputation token
        reputationEngine = ReputationEngine(
            reputationModule.createReputationEngine(
                address(reputationEngineMaster),
                address(repToken),
                REPUTATION_TOKEN_ID,
                REPUTATION_DECAY_RATE,
                REPUTATION_DECAY_INTERVAL
            )
        );

        // Reputation config
        ReputationModuleInterface.ReputationMarketConfig
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationEngine: address(reputationEngine),
                    signalStake: 1e18,
                    submitMin: 1e18,
                    submitMax: 100000e18
                });

        // Create a new labor market configuration
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new labor market
        market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: msg.sender,
                _configuration: config
            })
        );

        vm.stopBroadcast();
    }
}
