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

import {ScalableLikertEnforcement} from "src/Modules/Enforcement/ScalableLikertEnforcement.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract ScalableLikertEnforcementTest is PRBTest, StdCheats {
    Badger public badger;
    BadgerOrganization public badgerMaster;

    BadgerOrganization public repToken;
    PaymentToken public payToken;

    LaborMarket public marketImplementation;
    LaborMarket public market;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    ScalableLikertEnforcement public enforcement;

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
        enforcement = new ScalableLikertEnforcement();

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

        market = LaborMarket(
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
        payToken.approve(address(market), 1_000e18);

        vm.stopPrank();
    }

    function createSimpleRequest(LaborMarket simpleMarket, uint256 pTokenQ)
        internal
        returns (uint256)
    {
        uint256 rid = simpleMarket.submitRequest({
            _pToken: address(payToken),
            _pTokenQ: pTokenQ,
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

    function test_ScalableLikertRandomReviews() public {
        vm.startPrank(deployer);
        // vm.assume(ptokenQ < 643289384651756641242061027826043932518166581475780911330319911155072942);

        uint256 runs = 100;
        uint256 ptokenQ = 1000e32;
        payToken.freeMint(bob, ptokenQ);

        changePrank(bob);

        payToken.approve(address(market), ptokenQ);
        // Create a request
        uint256 requestId = createSimpleRequest(market, ptokenQ);

        // Signal the request on 20 accounts
        for (uint256 i = requestId; i < requestId + runs; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            market.signal(requestId);
            market.provide(requestId, "0x");
        }

        changePrank(bob);
        market.signalReview(requestId, runs);

        changePrank(bobert);
        market.signalReview(requestId, runs);

        changePrank(delegate);
        market.signalReview(requestId, runs);

        changePrank(grader1);
        market.signalReview(requestId, runs);

        changePrank(grader2);
        market.signalReview(requestId, runs);

        uint256 salt = 0;
        for (uint256 i = requestId; i < requestId + runs; i++) {
            changePrank(delegate);
            salt = (salt * i + i + 2) % 1000;
            market.review(requestId, i + 1, randomLikert(salt));
            changePrank(bobert);
            salt = (salt * i + i + 3) % 1000;
            market.review(requestId, i + 1, randomLikert(salt));
            changePrank(bob);
            salt = (salt * i + i + 4) % 1000;
            market.review(requestId, i + 1, randomLikert(salt));
            changePrank(grader1);
            salt = (salt * i + i + 3) % 1000;
            market.review(requestId, i + 1, randomLikert(salt));
            changePrank(grader2);
            salt = (salt * i + i + 2) % 1000;
            market.review(requestId, i + 1, randomLikert(salt));
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
            (uint256 pPaid, uint256 rPaid) = market.claim(i + 1, msg.sender); 
            totalPaid += pPaid;
            totalReputation += rPaid;
        }

        console.log("pTokenDust %s / %s", ptokenQ - totalPaid, ptokenQ);
        console.log("rTokenDust %s / %s", 5000 - totalReputation, 5000);

        assertAlmostEq(totalPaid, ptokenQ, 1e8);
        assertAlmostEq(totalReputation, 5000, 100);
    }

    function test_ScalableLikertMarketSimple() public {
        vm.startPrank(deployer);

        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(market, 1000e18);

        // Signal the request on 5 accounts
        for (uint256 i = requestId; i < requestId + 5; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            market.signal(requestId);
            uint256 subId = market.provide(requestId, "0x");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        market.signalReview(requestId, 5);

        uint256 counter = 0;
        for (uint256 i = requestId; i < requestId + 5; i++) {
            market.review(requestId, i + 1, counter);
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
            (uint256 pPaid, uint256 rPaid) = market.claim(i + 1, msg.sender); 
            totalPaid += pPaid;
            totalReputation += rPaid;
        }

        console.log("pTokenDust %s / %s", 1000e18 - totalPaid, 1000e18);
        console.log("rTokenDust %s / %s", 5000 - totalReputation, 5000);

        assertAlmostEq(totalPaid, 1000e18, 1e6);
        assertAlmostEq(totalReputation, 5000, 100);
    }

    function test_ScalableLikertMarketBase() public {
        vm.startPrank(deployer);

        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(market, 1000e18);

        for (uint256 i = requestId + 1; i < requestId + 11; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, DELEGATE_TOKEN_ID, 1, "0x");
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            market.signal(requestId);
            market.provide(requestId, "NaN");
        }

        changePrank(bob);
        market.signalReview(requestId, 10);

        changePrank(bobert);
        market.signalReview(requestId, 10);

        changePrank(delegate);
        market.signalReview(requestId, 10);

        changePrank(grader1);
        market.signalReview(requestId, 10);

        changePrank(grader2);
        market.signalReview(requestId, 10);

        // The reviewer reviews the submissions
        for (uint256 i = requestId + 1; i < requestId + 11; i++) {
            if (i == requestId + 1) {
                market.review(requestId, i, 4);
            }
            if (i == requestId + 2) {
                market.review(requestId, i, 4);
                changePrank(bobert);
                market.review(requestId, i, 4);
            }
            if (i == requestId + 3) {
                market.review(requestId, i, 4);
                changePrank(bob);
                market.review(requestId, i, 4);
                changePrank(grader1);
                market.review(requestId, i, 3);
            }
            if (i == requestId + 4) {
                market.review(requestId, i, 3);
            }
            if (i == requestId + 5) {
                market.review(requestId, i, 3);
                changePrank(bobert);
                market.review(requestId, i, 2);
            }
            if (i == requestId + 6) {
                market.review(requestId, i, 2);
            }
            if (i == requestId + 7) {
                market.review(requestId, i, 2);
                changePrank(bob);
                market.review(requestId, i, 1);
            }
            if (i == requestId + 8) {
                market.review(requestId, i, 1);
            }
            if (i == requestId + 9) {
                market.review(requestId, i, 1);
                changePrank(bobert);
                market.review(requestId, i, 0);
                changePrank(grader1);
                market.review(requestId, i, 0);
            }
            if (i == requestId + 10) {
                market.review(requestId, i, 0);
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
            (uint256 pPaid, uint256 rPaid) = market.claim(i, msg.sender); 
            totalPaid += pPaid;
            totalReputation += rPaid;
        }

        console.log("pTokenDust %s / %s", 1000e18 - totalPaid, 1000e18);
        console.log("rTokenDust %s / %s", 5000 - totalReputation, 5000);

        assertAlmostEq(totalPaid, 1000e18, 1e6);
        assertAlmostEq(totalReputation, 5000, 100);
    }

        function test_CanReclaimUnusedPayment() public {
        vm.startPrank(deployer);

        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(market, 1000e18);

        // Signal the request on 112 accounts
        for (uint256 i = requestId; i < 113; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, DELEGATE_TOKEN_ID, 1, "0x");
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            market.signal(requestId);
            market.provide(requestId, "NaN");
        }

        // Skip to enforcement deadline
        vm.warp(100 weeks);

        // Claim remainder
        changePrank(bob);
        uint256 balanceBefore = payToken.balanceOf(bob);
        market.claimRemainder(requestId);

        uint256 balanceAfter = payToken.balanceOf(bob);

        assertEq(balanceAfter - balanceBefore, 1000e18);
    }

    function test_ScalableLikertCanReclaimPaymentWithSubmissions() public {
        vm.startPrank(deployer);

        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(market, 1000e18);

        // Signal the request
        for (uint256 i = requestId; i < 10; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, DELEGATE_TOKEN_ID, 1, "0x");
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            market.signal(requestId);
            uint256 id = market.provide(requestId, "NaN");
        }

        /// Cannot withdraw as signals exist
        changePrank(bob);
        vm.expectRevert("LaborMarket::withdrawRequest: Already active");
        market.withdrawRequest(requestId);

        // Have bob review a submission
        market.signalReview(requestId, 1);
        market.review(requestId, 5, 1);

        changePrank(grader1);
        market.signalReview(requestId, 1);
        market.review(requestId, 5, 0);

        changePrank(grader2);
        market.signalReview(requestId, 1);
        market.review(requestId, 5, 0);

        // Skip to enforcement deadline
        vm.warp(100 weeks);

        // Claim remainder (should be 0)
        changePrank(bob);
        uint256 balanceBefore = payToken.balanceOf(bob);
        market.claimRemainder(requestId);
        uint256 balanceAfter = payToken.balanceOf(bob);
        assertEq(balanceAfter - balanceBefore, 1000e18);
    }

    function test_ScalableLikertCannotReclaimUsedPayment() public {
        vm.startPrank(deployer);

        payToken.freeMint(bob, 10000e18);

        changePrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(market, 1000e18);

        // Signal the request on 112 accounts
        for (uint256 i = requestId; i < 10; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.leaderMint(user, DELEGATE_TOKEN_ID, 1, "0x");
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            changePrank(user);

            market.signal(requestId);
            uint256 id = market.provide(requestId, "NaN");
        }

        /// Cannot withdraw as signals exist
        changePrank(bob);
        vm.expectRevert("LaborMarket::withdrawRequest: Already active");
        market.withdrawRequest(requestId);

        // Have bob review a submission
        market.signalReview(requestId, 1);
        market.review(requestId, 5, 1);

        // Skip to enforcement deadline
        vm.warp(100 weeks);

        // Claim remainder (should be 0)
        changePrank(bob);
        uint256 balanceBefore = payToken.balanceOf(bob);
        market.claimRemainder(requestId);
        uint256 balanceAfter = payToken.balanceOf(bob);
        assertEq(balanceAfter - balanceBefore, 0);
    }
}
