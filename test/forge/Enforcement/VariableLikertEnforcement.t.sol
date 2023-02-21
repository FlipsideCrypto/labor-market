// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "prb-test/PRBTest.sol";

// Contracts
import {PaymentToken} from "../Helpers/HelperTokens.sol";
import { BadgerOrganization } from "src/Modules/Badger/BadgerOrganization.sol";
import { Badger } from "src/Modules/Badger/Badger.sol";
import { BadgerScoutInterface } from "src/Modules/Badger/interfaces/BadgerScoutInterface.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import {VariableLikertEnforcement} from "src/Modules/Enforcement/VariableLikertEnforcement.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract VariableLikertEnforcementTest is PRBTest, StdCheats {
    Badger public badger;
    BadgerOrganization public badgerMaster;

    BadgerOrganization public repToken;
    PaymentToken public payToken;

    LaborMarket public marketImplementation;
    LaborMarket public constantLikertMarket;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    VariableLikertEnforcement public enforcement;

    // Define the tokenIds for ERC1155
    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;
    uint256 private constant MAINTAINER_TOKEN_ID = 3;
    uint256 private constant GOVERNOR_TOKEN_ID = 4;
    uint256 private constant CREATOR_TOKEN_ID = 5;
    uint256 private constant REPUTATION_DECAY_RATE = 0;
    uint256 private constant REPUTATION_DECAY_INTERVAL = 0;

    uint256[] private RANGES;
    uint256[] private WEIGHTS;

    address private deployer = address(0xDe);
    address private bob = address(0x1);
    address private bobert = address(0x11);
    address private grader1 = address(0x111);
    address private grader2 = address(0x222);
    address private alice = address(0x2);
    address private delegate = address(0x3);

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        payToken = new PaymentToken(deployer);

        // Create badger factory
        badgerMaster = new BadgerOrganization();
        badger = new Badger(address(badgerMaster));

        // Create reputation and role token contract
        repToken = BadgerOrganization(
            payable(badger.createOrganization(
                address(badgerMaster),
                address(deployer),
                "ipfs://000",
                "ipfs://000",
                "MDAO",
                "MDAO"
            )
        ));

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(payToken),
            _governorBadge: LaborMarketConfigurationInterface.BadgePair({
                token: address(repToken),
                tokenId: GOVERNOR_TOKEN_ID
            }),
            _creatorBadge: LaborMarketConfigurationInterface.BadgePair({
                token: address(repToken),
                tokenId: CREATOR_TOKEN_ID
            })
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));


        // Initialize reputation and roles
        address[] memory delegates = new address[](1);
        delegates[0] = address(reputationModule);
        for (uint256 i=0; i <= CREATOR_TOKEN_ID; i++) {
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

        // Make deployer a governor and creator
        repToken.leaderMint(address(deployer), GOVERNOR_TOKEN_ID, 1, "0x");
        repToken.leaderMint(address(deployer), CREATOR_TOKEN_ID, 1, "0x");

        // Create enforcement criteria
        enforcement = new VariableLikertEnforcement();

        RANGES.push(0); RANGES.push(24); RANGES.push(44); RANGES.push(69); RANGES.push(89);
        WEIGHTS.push(0); WEIGHTS.push(25); WEIGHTS.push(75); WEIGHTS.push(100); WEIGHTS.push(200);

        bytes32 key = "aggressive";

        // Set the buckets
        enforcement.setBuckets(key, RANGES, WEIGHTS);

        // Create a new labor market configuration for constant likert
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory constantLikertConfig = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    marketUri: "ipfs://000",
                    owner: address(deployer),
                    modules: LaborMarketConfigurationInterface.Modules({
                        network: address(network),
                        reputation: address(reputationModule),
                        enforcement: address(enforcement),
                        enforcementKey: key
                    }),
                    maintainerBadge: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: MAINTAINER_TOKEN_ID
                    }),
                    delegateBadge: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: DELEGATE_TOKEN_ID
                    }),
                    reputationBadge: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: REPUTATION_TOKEN_ID
                    }),
                    reputationParams: LaborMarketConfigurationInterface.ReputationParams({
                        rewardPool: 5000,
                        provideStake: 5,
                        reviewStake: 5,
                        submitMin: 10,
                        submitMax: 10000e18
                    })
                });

        constantLikertMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _configuration: constantLikertConfig
            })
        );

        // Approve and mint tokens
        repToken.leaderMint(alice, REPUTATION_TOKEN_ID, 100e18, "0x");
        repToken.leaderMint(alice, DELEGATE_TOKEN_ID, 1, "0x");

        changePrank(deployer);
        repToken.leaderMint(bob, REPUTATION_TOKEN_ID, 100000e18, "0x");
        repToken.leaderMint(bob, DELEGATE_TOKEN_ID, 1, "0x");
        payToken.freeMint(bob, 1_000_000e18);
        repToken.leaderMint(bob, MAINTAINER_TOKEN_ID, 1, "0x");
        repToken.leaderMint(bobert, MAINTAINER_TOKEN_ID, 1, "0x");
        repToken.leaderMint(bobert, REPUTATION_TOKEN_ID, 1_000_000e18, "0x");
        repToken.leaderMint(delegate, REPUTATION_TOKEN_ID, 1_000_000e18, "0x");
        repToken.leaderMint(delegate, MAINTAINER_TOKEN_ID, 1, "0x");
        repToken.leaderMint(grader1, REPUTATION_TOKEN_ID, 1_000_000e18, "0x");
        repToken.leaderMint(grader1, MAINTAINER_TOKEN_ID, 1, "0x");
        repToken.leaderMint(grader2, REPUTATION_TOKEN_ID, 1_000_000e18, "0x");
        repToken.leaderMint(grader2, MAINTAINER_TOKEN_ID, 1, "0x");

        changePrank(bob);
        payToken.approve(address(constantLikertMarket), 1_000e18);

        vm.stopPrank();
    }

    function createSimpleRequest(LaborMarket simpleMarket)
        internal
        returns (uint256)
    {
        uint256 rid = simpleMarket.submitRequest({
            _pToken: address(payToken),
            _pTokenQ: 1000e18,
            _signalExp: block.timestamp + 1 hours,
            _submissionExp: block.timestamp + 1 days,
            _enforcementExp: block.timestamp + 1 weeks,
            _requestUri: "ipfs://222"
        });

        return rid;
    }

    function pseudoRandom(uint256 _n, uint256 _salt) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, _n, _salt))
            ) / 1.5e75;
    }

    function randomLikert(uint256 salt) internal view returns (uint256) {
        return (pseudoRandom(123, salt) + uint160(msg.sender) + uint256(salt)) % 5;
    }

    function test_VariableLikertRandomReviews() public {
        vm.startPrank(deployer);

        uint256 runs = 400;
        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(constantLikertMarket);

        // Signal the request on 20 accounts
        for (uint256 i = requestId; i < requestId + runs; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            constantLikertMarket.signal(requestId);
            constantLikertMarket.provide(requestId, "0x");
        }

        changePrank(bob);
        constantLikertMarket.signalReview(requestId, runs);

        changePrank(bobert);
        constantLikertMarket.signalReview(requestId, runs);

        changePrank(delegate);
        constantLikertMarket.signalReview(requestId, runs);

        changePrank(grader1);
        constantLikertMarket.signalReview(requestId, runs);

        changePrank(grader2);
        constantLikertMarket.signalReview(requestId, runs);

        uint256 salt = 0;
        for (uint256 i = requestId; i < requestId + runs; i++) {
            changePrank(delegate);
            salt = (salt * i + i + 2) % 1000;
            constantLikertMarket.review(requestId, i + 1, randomLikert(salt));
            changePrank(bobert);
            salt = (salt * i + i + 3) % 1000;
            constantLikertMarket.review(requestId, i + 1, randomLikert(salt));
            changePrank(bob);
            salt = (salt * i + i + 4) % 1000;
            constantLikertMarket.review(requestId, i + 1, randomLikert(salt));
            changePrank(grader1);
            salt = (salt * i + i + 3) % 1000;
            constantLikertMarket.review(requestId, i + 1, randomLikert(salt));
            changePrank(grader2);
            salt = (salt * i + i + 2) % 1000;
            constantLikertMarket.review(requestId, i + 1, randomLikert(salt));
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;
        uint256 totalReputation;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i = requestId; i < requestId + runs; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            (uint256 pPaid, uint256 rPaid) = constantLikertMarket.claim(i + 1, msg.sender); 
            totalPaid += pPaid;
            totalReputation += rPaid;
        }

        console.log("totalPaid", totalPaid);
        console.log("totalReputation", totalReputation);
        console.log("dust", 1000e18 - totalPaid);
        console.log("repDust", 5000 - totalReputation);

        assertAlmostEq(totalPaid, 1000e18, 0.00001e18);
    }

    function test_VariableLikertMarketSimple() public {
        vm.startPrank(deployer);

        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(constantLikertMarket);

        // Signal the request on 5 accounts
        for (uint256 i = requestId; i < requestId + 5; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            constantLikertMarket.signal(requestId);
            uint256 subId = constantLikertMarket.provide(requestId, "0x");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        constantLikertMarket.signalReview(requestId, 5);

        uint256 counter = 0;
        for (uint256 i = requestId; i < requestId + 5; i++) {
            constantLikertMarket.review(requestId, i + 1, counter);
            counter++;
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;
        uint256 totalReputation;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i = requestId; i < requestId + 5; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            (uint256 pPaid, uint256 rPaid) = constantLikertMarket.claim(i + 1, msg.sender); 
            totalPaid += pPaid;
            totalReputation += rPaid;
        }

        console.log("totalPaid", totalPaid);
        console.log("totalReputation", totalReputation);
        console.log("dust", 1000e18 - totalPaid);
        console.log("repDust", 5000 - totalReputation);

        assertAlmostEq(totalPaid, 1000e18, 0.00001e18);
    }

    function test_VariableLikertMarketBase() public {
        vm.startPrank(deployer);

        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(constantLikertMarket);

        for (uint256 i = requestId + 1; i < requestId + 11; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, DELEGATE_TOKEN_ID, 1, "0x");
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            constantLikertMarket.signal(requestId);
            constantLikertMarket.provide(requestId, "NaN");
        }

        changePrank(bob);
        constantLikertMarket.signalReview(requestId, 10);

        changePrank(bobert);
        constantLikertMarket.signalReview(requestId, 10);

        changePrank(delegate);
        constantLikertMarket.signalReview(requestId, 10);

        changePrank(grader1);
        constantLikertMarket.signalReview(requestId, 10);

        changePrank(grader2);
        constantLikertMarket.signalReview(requestId, 10);

        // The reviewer reviews the submissions
        for (uint256 i = requestId + 1; i < requestId + 11; i++) {
            if (i == requestId + 1) {
                constantLikertMarket.review(requestId, i, 4);
            }
            if (i == requestId + 2) {
                constantLikertMarket.review(requestId, i, 4);
                changePrank(bobert);
                constantLikertMarket.review(requestId, i, 4);
            }
            if (i == requestId + 3) {
                constantLikertMarket.review(requestId, i, 4);
                changePrank(bob);
                constantLikertMarket.review(requestId, i, 4);
                changePrank(grader1);
                constantLikertMarket.review(requestId, i, 3);
            }
            if (i == requestId + 4) {
                constantLikertMarket.review(requestId, i, 3);
            }
            if (i == requestId + 5) {
                constantLikertMarket.review(requestId, i, 3);
                changePrank(bobert);
                constantLikertMarket.review(requestId, i, 2);
            }
            if (i == requestId + 6) {
                constantLikertMarket.review(requestId, i, 2);
            }
            if (i == requestId + 7) {
                constantLikertMarket.review(requestId, i, 2);
                changePrank(bob);
                constantLikertMarket.review(requestId, i, 1);
            }
            if (i == requestId + 8) {
                constantLikertMarket.review(requestId, i, 1);
            }
            if (i == requestId + 9) {
                constantLikertMarket.review(requestId, i, 1);
                changePrank(bobert);
                constantLikertMarket.review(requestId, i, 0);
                changePrank(grader1);
                constantLikertMarket.review(requestId, i, 0);
            }
            if (i == requestId + 10) {
                constantLikertMarket.review(requestId, i, 0);
            }
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;
        uint256 totalReputation;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i = requestId + 1; i < requestId + 11; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            (uint256 pPaid, uint256 rPaid) = constantLikertMarket.claim(i, msg.sender); 
            totalPaid += pPaid;
            totalReputation += rPaid;
            console.log("paid [%s]: %s", i, pPaid);
        }
        console.log("totalPaid", totalPaid);
        console.log("totalReputation", totalReputation);
        console.log("dust", 1000e18 - totalPaid);
        console.log("repDust", 5000 - totalReputation);

        assertAlmostEq(totalPaid, 1000e18, 0.00001e18);
    }
}