// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {Cheats} from "forge-std/Cheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

// Contracts
import {AnyReputationToken, PaymentToken} from "./Helpers/HelperTokens.sol";
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
import {FCFSEnforcementCriteria} from "src/Modules/Enforcement/FCFSEnforcementCriteria.sol";
import {Best5EnforcementCriteria} from "src/Modules/Enforcement/Best5EnforcementCriteria.sol";

import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract ContractTest is PRBTest, Cheats {
    AnyReputationToken public repToken;
    PaymentToken public payToken;

    LaborMarket public marketImplementation;
    LaborMarket public likertMarket;
    LaborMarket public fcfsMarket;
    LaborMarket public best5Market;

    ReputationEngine public reputationEngineMaster;
    ReputationEngine public reputationEngine;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    LikertEnforcementCriteria public likertEnforcement;
    FCFSEnforcementCriteria public fcfsEnforcement;
    Best5EnforcementCriteria public best5Enforcement;

    PaymentModule public paymentModule;
    PayCurve public payCurve;

    // Define the tokenIds for ERC1155
    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;
    uint256 private constant MAINTAINER_TOKEN_ID = 3;
    uint256 private constant REPUTATION_DECAY_RATE = 0;
    uint256 private constant REPUTATION_DECAY_INTERVAL = 0;

    // Deployer
    address private deployer = address(0xDe);

    // Maintainer
    address private bob = address(0x1);

    // Maintainer 2
    address private bobert = address(0x11);

    // User
    address private alice = address(0x2);

    // Evil user
    address private evilUser =
        address(uint160(uint256(keccak256("EVIL_USER"))));

    // Alt delegate
    // Evil user
    address private delegate =
        address(uint160(uint256(keccak256("DELEGATOOOR"))));

    // Events
    event MarketParametersUpdated(
        LaborMarketConfigurationInterface.LaborMarketConfiguration indexed configuration
    );

    event RequestWithdrawn(uint256 indexed requestId);

    event LaborMarketCreated(
        address indexed organization,
        address indexed owner,
        address indexed implementation
    );

    event RequestCreated(
        address indexed requester,
        uint256 indexed requestId,
        string indexed uri,
        address pToken,
        uint256 pTokenId,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp
    );

    event RequestSignal(
        address indexed signaler,
        uint256 indexed requestId,
        uint256 signalAmount
    );

    event ReviewSignal(
        address indexed signaler,
        uint256 indexed quantity,
        uint256 signalAmount
    );

    event RequestFulfilled(
        address indexed fulfiller,
        uint256 indexed requestId,
        uint256 indexed submissionId
    );

    event RequestReviewed(
        address reviewer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 indexed reviewScore
    );

    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed submissionId,
        uint256 indexed payAmount,
        address to
    );

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        payToken = new PaymentToken();

        // Generic reputation token
        repToken = new AnyReputationToken("reputation nation");

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
        likertEnforcement = new LikertEnforcementCriteria();
        fcfsEnforcement = new FCFSEnforcementCriteria();
        best5Enforcement = new Best5EnforcementCriteria();

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
                    providerThreshold: 1e18,
                    maintainerThreshold: 100e18
                });

        // Create a new labor market configuration for likert
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory likertConfig = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(likertEnforcement),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new labor market configuration for fcfs
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory fcfsConfig = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(fcfsEnforcement),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new labor market configuration for best5
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory best5Config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(best5Enforcement),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new likert labor market
        likertMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: likertConfig
            })
        );

        // Create a new fcfs labor market
        fcfsMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: fcfsConfig
            })
        );

        // Create a new best5 labor market
        best5Market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: best5Config
            })
        );

        // Approve and mint tokens
        changePrank(alice);
        repToken.freeMint(alice, REPUTATION_TOKEN_ID, 100e18);
        repToken.freeMint(alice, DELEGATE_TOKEN_ID, 1);
        repToken.setApprovalForAll(address(likertMarket), true);
        repToken.setApprovalForAll(address(fcfsMarket), true);
        repToken.setApprovalForAll(address(best5Market), true);

        changePrank(bob);
        repToken.freeMint(bob, REPUTATION_TOKEN_ID, 1000e18);
        repToken.freeMint(bob, DELEGATE_TOKEN_ID, 1);
        payToken.freeMint(bob, 1_000_000e18);

        repToken.freeMint(bob, MAINTAINER_TOKEN_ID, 1);
        repToken.setApprovalForAll(address(likertMarket), true);
        repToken.setApprovalForAll(address(fcfsMarket), true);
        repToken.setApprovalForAll(address(best5Market), true);

        payToken.approve(address(likertMarket), 1_000e18);
        payToken.approve(address(fcfsMarket), 1_000e18);
        payToken.approve(address(best5Market), 1_000e18);

        changePrank(bobert);
        repToken.freeMint(bobert, REPUTATION_TOKEN_ID, 1000e18);
        repToken.freeMint(bobert, MAINTAINER_TOKEN_ID, 1);
        repToken.setApprovalForAll(address(likertMarket), true);
        repToken.setApprovalForAll(address(fcfsMarket), true);
        repToken.setApprovalForAll(address(best5Market), true);

        changePrank(delegate);
        repToken.freeMint(delegate, DELEGATE_TOKEN_ID, 1);

        vm.stopPrank();
    }

    function createSimpleRequest(LaborMarket simpleMarket)
        internal
        returns (uint256)
    {
        uint256 rid = simpleMarket.submitRequest({
            pToken: address(payToken),
            pTokenId: PAYMENT_TOKEN_ID,
            pTokenQ: 1000e18,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        return rid;
    }

    function pseudoRandom(uint256 _n) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, _n))
            ) / 1.5e75;
    }

    function test_LikertMarket() public {
        /**
        | Here we test the workings of enforcement (reviewing) following a likert metric.
        |
        | First, we populate the request with submissions
        | Second, we review the submissions
        | Third, we test the enforcement criteria following an example scenario.
        | 
        | * Example scenario:
        | pTokens: 1000
        | Participants: 112
        | Likert ratings: (1, BAD), (2, OK), (3, GOOD)
        | Bucket distribution: (1, 66), (2, 36), (3, 10)
        | Payout distribution: (1, 0), (2, 20%), (3, 80%)
        | Expected Tokens per person per bucket: (1, 0), (2, 5.5), (3, 80)
        */

        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(likertMarket);

        // Signal the request on 112 accounts
        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Mint required tokens
            repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);

            // Aprove the market
            repToken.setApprovalForAll(address(likertMarket), true);

            likertMarket.signal(requestId);
            likertMarket.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        likertMarket.signalReview(115);

        // The reviewer reviews the submissions
        for (uint256 i; i < 113; i++) {
            if (i < 67) {
                // BAD
                likertMarket.review(requestId, i + 1, 0);
            } else if (i < 103) {
                // OK
                likertMarket.review(requestId, i + 1, 1);
            } else {
                // GOOD
                likertMarket.review(requestId, i + 1, 2);
            }
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            totalPaid += likertMarket.claim(i + 1, msg.sender, "");
        }

        assertAlmostEq(totalPaid, 1000e18, 0.000001e18);
    }

    function test_Best5Market() public {
        /**
        | Here we test the workings of enforcement (reviewing) following a top 5 metric
        |
        | First, we populate the request with submissions
        | Second, we review the submissions
        | Third, we sort the submissions based on review ranking
        | 
        | * Example scenario:
        | pTokens: 1000
        | Participants: 112
        | Likert ratings: (1, BAD), (2, OK), (3, GOOD)
        | Bucket distribution: (1, 66), (2, 36), (3, 10)
        | Payout distribution: (1, 0), (2, 20%), (3, 80%)
        | Expected Tokens per person per bucket: (1, 0), (2, 5.5), (3, 80)
        */

        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(best5Market);

        // Signal the request on 112 accounts
        for (uint256 i; i < 55; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Mint required tokens
            repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);

            // Aprove the market
            repToken.setApprovalForAll(address(best5Market), true);

            best5Market.signal(requestId);
            best5Market.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        best5Market.signalReview(115);

        // The reviewer reviews the submissions
        for (uint256 i; i < 55; i++) {
            best5Market.review(requestId, i + 1, pseudoRandom(i));
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i; i < 55; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            totalPaid += best5Market.claim(i + 1, msg.sender, "");
        }

        best5Enforcement.getSubmissions(address(best5Market), requestId);

        assertAlmostEq(totalPaid, 1000e18, 0.000001e18);
    }

    function test_FcfsMarket() public {}
}
