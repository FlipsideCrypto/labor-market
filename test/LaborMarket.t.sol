// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {Cheats} from "forge-std/Cheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

// Contracts
import {ReputationToken, CapacityToken} from "./Helpers/HelperTokens.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {EnforcementModule} from "src/Modules/Enforcement/EnforcementModule.sol";
import {EnforcementCriteria} from "src/Modules/Enforcement/EnforcementCriteria.sol";

import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract ContractTest is PRBTest, Cheats {
    ReputationToken public repToken;
    CapacityToken public capToken;

    LaborMarket public implementation;
    LaborMarket public market;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    EnforcementModule public enforcementModule;
    EnforcementCriteria public enforcementCriteria;
    PaymentModule public paymentModule;
    PayCurve public payCurve;

    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;

    address private deployer = address(0xDe);

    address private bob = address(0x1);
    address private alice = address(0x2);

    event LaborMarketCreated(
        address indexed organization,
        address indexed owner,
        address indexed implementation
    );

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        repToken = new ReputationToken("ipfs://000");
        capToken = new CapacityToken();

        // Deploy an empty labor market for implementation
        implementation = new LaborMarket();

        // Deploy a labor market factory
        factory = new LaborMarketFactory(address(implementation));

        LaborMarketNetworkInterface.ReputationTokenConfig
            memory repConfig = LaborMarketNetworkInterface
                .ReputationTokenConfig({
                    manager: deployer,
                    decayRate: 0,
                    decayInterval: 0,
                    baseSignalStake: 1e18,
                    baseMaintainerThreshold: 100e18,
                    baseProviderThreshold: 10e18
                });

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(implementation),
            _capacityImplementation: address(capToken),
            _baseReputationImplementation: address(repToken),
            _baseReputationTokenId: REPUTATION_TOKEN_ID,
            _baseReputationConfig: repConfig
        });

        // Create enforcement criteria
        enforcementCriteria = new EnforcementCriteria();

        // Create a payment module
        paymentModule = new PaymentModule();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Create a new labor market
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    reputationToken: address(repToken),
                    reputationTokenId: REPUTATION_TOKEN_ID,
                    repParticipantMultiplier: 1,
                    repMaintainerMultiplier: 1,
                    marketUri: "ipfs://000"
                });

        market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(implementation),
                _deployer: deployer,
                _configuration: config
            })
        );

        // Approve and mint tokens
        changePrank(alice);
        repToken.freeMint(alice, REPUTATION_TOKEN_ID, 100e18);
        repToken.freeMint(alice, DELEGATE_TOKEN_ID, 1);
        repToken.setApprovalForAll(address(market), true);

        changePrank(bob);
        repToken.freeMint(bob, REPUTATION_TOKEN_ID, 1000e18);
        repToken.freeMint(bob, DELEGATE_TOKEN_ID, 1);
        repToken.setApprovalForAll(address(market), true);

        vm.stopPrank();
    }

    function createSimpleRequest(LaborMarket simpleMarket)
        internal
        returns (uint256)
    {
        uint256 rid = simpleMarket.submitRequest({
            pToken: address(repToken),
            pTokenId: PAYMENT_TOKEN_ID,
            pTokenQ: 100e18,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        return rid;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function test_CreateServiceRequest() public {
        /**
        | Here we test the creation of a service request
        | A service request contains:
        |  - A payment token (ERC1155)
        |  - A payment token ID
        |  - A payment token quantity
        |  - A signal expiration
        |  - A submission expiration
        |  - An enforcement expiration
        |  - A request URI
        |
        | First, we test that the request is created correctly
        | Second, we test that the request is allowed to be signaled
        | Third, we test the workings of a service submission
        | Fourth, we test the workings of a service enforcement
        | Finally, we test the workings of a service payment (claiming)
        */

        // Instrument an admin
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = market.submitRequest({
            pToken: address(repToken),
            pTokenId: PAYMENT_TOKEN_ID,
            pTokenQ: 100e18,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        // Verify the request was created
        assertEq(market.serviceRequestId(), 1);
        assertEq(market.getRequest(requestId).serviceRequester, bob);
        assertEq(market.getRequest(requestId).pToken, address(repToken));

        // Signal the request
        changePrank(alice);
        market.signal(requestId);

        // Verify signaling logic
        assertTrue(market.submissionSignals(requestId, alice));

        // Fulfill the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        changePrank(bob);
        // Review the request
        market.signalReview(requestId, 2);
        market.review(requestId, submissionId, 2);

        // Claim the reward
        changePrank(alice);

        // Skip to enforcement deadline
        vm.warp(5 weeks);
        market.claim(submissionId);
    }

    function test_ExampleEnforcementTest() public {
        /**
        | Here we test the workings of enforcement (reviewing)
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
        uint256 requestId = createSimpleRequest(market);

        // Signal the request on 112 accounts
        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Mint required tokens
            repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);

            // Aprove the market
            repToken.setApprovalForAll(address(market), true);

            market.signal(requestId);
            market.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        market.signalReview(requestId, 115);

        // The reviewer reviews the submissions
        for (uint256 i; i < 113; i++) {
            if (i < 67) {
                // BAD
                market.review(requestId, i + 1, 0);
            } else if (i < 103) {
                // OK
                market.review(requestId, i + 1, 1);
            } else {
                // GOOD
                market.review(requestId, i + 1, 2);
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
            totalPaid += market.claim(i + 1);
        }

        assertAlmostEq(totalPaid, 1000e18, 0.000001e18);
    }

    function test_CreateMultipleMarkets() public {
        /**
        | Here we test the ability to create multiple functional labor markets.
        |
        | First, we generate 10 markets
        | Second, we create a request on each market
        | Third, we test signaling, reviewing and claiming.
        | Finally, we monitor that the market creation events are emitted correctly.
        */
        vm.startPrank(deployer);

        // Example configuration
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    reputationToken: address(repToken),
                    reputationTokenId: REPUTATION_TOKEN_ID,
                    repParticipantMultiplier: 1,
                    repMaintainerMultiplier: 1,
                    marketUri: "ipfs://000"
                });

        // Create 10 markets
        for (uint256 i; i <= 10; ++i) {
            vm.expectEmit(false, true, true, true);
            emit LaborMarketCreated(
                address(market),
                deployer,
                address(implementation)
            );
            market = LaborMarket(
                network.createLaborMarket({
                    _implementation: address(implementation),
                    _deployer: deployer,
                    _configuration: config
                })
            );

            // Populate all markets with a demo request
            changePrank(bob);
            uint256 requestId = createSimpleRequest(market);

            changePrank(alice);
            market.signal(requestId);
            market.provide(requestId, "IPFS://333");

            changePrank(bob);
            market.signalReview(requestId, 8);
            market.review(requestId, 1, 2);

            changePrank(alice);
            vm.warp(block.timestamp + 5 weeks);
            market.claim(requestId);
        }
        vm.stopPrank();
    }

    function test_ReputationalChangesBasedOnActions() public {
        /**
        | Here we test the fact taht performing actions on the market influences reputation.
        |
        | First, verify that a users reputation is locked on signaling.
        | Then, we verify that a maintainers reputation is locked on singaling for review.
        | Finally we verify that a users reputation is unlocked upon submission, and the maintainer on review.
        */
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // Signal the request
        changePrank(alice);
        market.signal(requestId);

        // Verify that Alice's reputation is locked
        assertEq(
            network.getAvailableReputation(
                alice,
                address(repToken),
                REPUTATION_TOKEN_ID
            ),
            (100e18 -
                network.getBaseSignalStake(
                    address(repToken),
                    REPUTATION_TOKEN_ID
                ))
        );

        // Fulfill the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Verify that Alice's reputation is unlocked
        assertEq(
            network.getAvailableReputation(
                alice,
                address(repToken),
                REPUTATION_TOKEN_ID
            ),
            100e18
        );

        changePrank(bob);

        // Review the request
        market.signalReview(requestId, 3);

        // Verify that Maintainers's reputation is locked
        assertEq(
            network.getAvailableReputation(
                bob,
                address(repToken),
                REPUTATION_TOKEN_ID
            ),
            (1000e18 -
                network.getBaseSignalStake(
                    address(repToken),
                    REPUTATION_TOKEN_ID
                ))
        );

        market.review(requestId, submissionId, 2);

        // Verify that the maintainer gets returned some reputation
        assertEq(
            network.getAvailableReputation(
                bob,
                address(repToken),
                REPUTATION_TOKEN_ID
            ),
            999333333333333333333 // (1000e18 - (2/3 * baseSignalStake))
        );

        // Claim the reward
        changePrank(alice);

        // Skip to enforcement deadline
        vm.warp(5 weeks);
        market.claim(submissionId);
    }

    function test_VerifyAllEmittedEvents() public {}

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROLS
    //////////////////////////////////////////////////////////////*/

    function test_PermittedParticipant() public {}

    function test_OnlyMaintainer() public {}

    function test_CanOnlyInitializeOnce() public {}

    function test_CanOnlySignalOnce() public {}

    function test_CanOnlySignalReviewOnce() public {}

    function test_CanOnlyReviewOnce() public {}

    function test_CanOnlyClaimOnce() public {}

    function test_CanOnlyProvideOnce() public {}

    function test_CannotSelfReview() public {}

    function test_CannotClaimOthersSubmission() public {}

    function test_VerifyReputationAccounting() public {}

    function test_VerifyClaimAccounting() public {}

    function test_CannotWithdrawActiveRequest() public {}

    function test_DeadlinesAreFunctional() public {}
}
