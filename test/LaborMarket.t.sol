// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {Cheats} from "forge-std/Cheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

// Contracts
import {AnyReputationToken, CapacityToken} from "./Helpers/HelperTokens.sol";
import {ReputationTokenInterface} from "src/MOdules/Reputation/interfaces/ReputationTokenInterface.sol";
import {ReputationToken} from "src/Modules/Reputation/ReputationToken.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import {EnforcementCriteria} from "src/Modules/Enforcement/EnforcementCriteria.sol";

import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract ContractTest is PRBTest, Cheats {
    AnyReputationToken public repToken;
    CapacityToken public capToken;

    LaborMarket public marketImplementation;
    LaborMarket public market;

    ReputationTokenInterface public reputationToken;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    EnforcementCriteria public enforcementCriteria;
    PaymentModule public paymentModule;
    PayCurve public payCurve;

    // Define the tokenIds for ERC1155
    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;

    // Deployer
    address private deployer = address(0xDe);

    // Maintainer
    address private bob = address(0x1);

    // User
    address private alice = address(0x2);

    // Evil user
    address private evilUser =
        address(uint160(uint256(keccak256("EVIL_USER"))));

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
        uint256 indexed requestId,
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
        uint256 indexed payAmount
    );

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        capToken = new CapacityToken();

        // Generic reputation token
        repToken = new AnyReputationToken("reputation nation");

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy reputation token implementation
        ReputationToken repTokImpl = new ReputationToken();

        // Deploy a labor market factory
        factory = new LaborMarketFactory(address(marketImplementation));

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(capToken)
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Create enforcement criteria
        enforcementCriteria = new EnforcementCriteria();

        // Create a payment module
        paymentModule = new PaymentModule();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Create a reputation token
        reputationToken = ReputationTokenInterface(
            reputationModule.createReputationToken(
                address(repTokImpl),
                address(repToken),
                REPUTATION_TOKEN_ID,
                0,
                0
            )
        );

        // Reputation config
        ReputationModuleInterface.ReputationMarketConfig
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationToken: address(reputationToken),
                    signalStake: 1e18,
                    providerThreshold: 1e18,
                    maintainerThreshold: 100e18
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
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new labor market
        market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
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

        ReputationModuleInterface.ReputationMarketConfig
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationToken: address(reputationToken),
                    signalStake: 1e18,
                    providerThreshold: 1e18,
                    maintainerThreshold: 100e18
                });

        // Example configuration
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create 10 markets
        for (uint256 i; i <= 10; ++i) {
            vm.expectEmit(false, true, true, true);
            emit LaborMarketCreated(
                address(market),
                deployer,
                address(marketImplementation)
            );
            market = LaborMarket(
                network.createLaborMarket({
                    _implementation: address(marketImplementation),
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
            reputationModule.getAvailableReputation(address(market), alice),
            (100e18 - reputationModule.getSignalStake(address(market)))
        );

        // Fulfill the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Verify that Alice's reputation is unlocked
        assertEq(
            reputationModule.getAvailableReputation(address(market), alice),
            100e18
        );

        changePrank(bob);

        // Review the request
        market.signalReview(requestId, 3);

        // Verify that Maintainers's reputation is locked
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            (1000e18 - reputationModule.getSignalStake(address(market)))
        );

        market.review(requestId, submissionId, 2);

        // Verify that the maintainer gets returned some reputation
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            999333333333333333333 // (1000e18 - (2/3 * signalStake))
        );

        // Claim the reward
        changePrank(alice);

        // Skip to enforcement deadline
        vm.warp(5 weeks);
        market.claim(submissionId);
    }

    function test_VerifyAllEmittedEvents() public {
        vm.startPrank(bob);

        ReputationModuleInterface.ReputationMarketConfig
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationToken: address(reputationToken),
                    signalStake: 1e18,
                    providerThreshold: 1e18,
                    maintainerThreshold: 100e18
                });

        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Verify market creation event
        vm.expectEmit(false, true, true, true);
        emit LaborMarketCreated(
            address(market),
            deployer,
            address(marketImplementation)
        );

        // Create a market
        market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: config
            })
        );

        // Verify service request creation event
        address pToken = address(repToken);
        uint256 pTokenId = PAYMENT_TOKEN_ID;
        uint256 pTokenQ = 100e18;
        uint256 signalExp = block.timestamp + 1 hours;
        uint256 submissionExp = block.timestamp + 1 days;
        uint256 enforcementExp = block.timestamp + 1 weeks;
        string memory requestUri = "ipfs://222";
        uint256 serviceRequestId;

        vm.expectEmit(true, false, true, true);
        emit RequestCreated(
            address(bob),
            serviceRequestId,
            requestUri,
            pToken,
            pTokenId,
            pTokenQ,
            signalExp,
            submissionExp,
            enforcementExp
        );

        uint256 requestId = createSimpleRequest(market);

        // Verify signaling events
        vm.expectEmit(true, true, true, true);
        emit RequestSignal(address(alice), requestId, 1e18);

        changePrank(alice);
        market.signal(requestId);

        vm.expectEmit(true, true, true, true);
        emit ReviewSignal(address(bob), requestId, 3, 1e18);

        changePrank(bob);
        market.signalReview(requestId, 3);

        // Verify submission events
        vm.expectEmit(true, true, true, true);
        emit RequestFulfilled(address(alice), requestId, 1);

        changePrank(alice);
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Verify reviewing events
        vm.expectEmit(true, true, true, true);
        emit RequestReviewed(address(bob), requestId, submissionId, 2);

        changePrank(bob);
        market.review(requestId, submissionId, 2);

        // Verify claiming events
        vm.expectEmit(true, true, true, true);
        emit RequestPayClaimed(
            address(alice),
            requestId,
            799999999973870935009 // (100e18 * 0.8)
        );

        changePrank(alice);
        vm.warp(block.timestamp + 5 weeks);
        market.claim(requestId);

        // Verify withdrawing request event
        changePrank(bob);
        uint256 requestId2 = createSimpleRequest(market);

        vm.expectEmit(true, false, false, true);
        emit RequestWithdrawn(requestId2);

        market.withdrawRequest(requestId2);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROLS
    //////////////////////////////////////////////////////////////*/

    function test_PermittedParticipant() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        changePrank(evilUser);

        // Try to signal the request and expect it to revert
        vm.expectRevert(
            "LaborMarket::permittedParticipant: Not a permitted participant"
        );
        market.signal(requestId);
        vm.stopPrank();
    }

    function test_OnlyMaintainer() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // A user tries to signal for review and we expect it to revert
        vm.expectRevert("LaborMarket::onlyMaintainer: Not a maintainer");
        market.signalReview(requestId, 3);

        // We also expect a revert if a random address tries to review
        changePrank(evilUser);

        vm.expectRevert("LaborMarket::onlyMaintainer: Not a maintainer");
        market.signalReview(requestId, 3);

        vm.stopPrank();
    }

    function test_CanOnlyInitializeOnce() public {
        vm.startPrank(deployer);

        ReputationModuleInterface.ReputationMarketConfig
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationToken: address(reputationToken),
                    signalStake: 1e18,
                    providerThreshold: 1e18,
                    maintainerThreshold: 100e18
                });

        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Attempt to initialize the market again and expect it to revert
        vm.expectRevert("Initializable: contract is already initialized");
        market.initialize(config);
        vm.stopPrank();
    }

    function test_CanOnlySignalOnce() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // Valid user tries to signal same request again and we expect it to revert
        vm.expectRevert("LaborMarket::signal: Already signaled.");
        market.signal(requestId);

        vm.stopPrank();
    }

    function test_CanOnlySignalReviewOnce() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A maintainer signals for review
        changePrank(bob);
        market.signalReview(requestId, 3);

        // Maintainer tries to signal same request again and we expect it to revert
        vm.expectRevert("LaborMarket::signalReview: Already signaled.");
        market.signalReview(requestId, 3);

        vm.stopPrank();
    }

    function test_CanOnlyReviewOnce() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        changePrank(alice);
        market.signal(requestId);
        market.provide(requestId, "ipfs://000");

        // A maintainer signals for review
        changePrank(bob);
        market.signalReview(requestId, 3);

        // Maintainer tries to review twice
        market.review(requestId, 1, 2);

        vm.expectRevert("LaborMarket::review: Already reviewed.");
        market.review(requestId, 1, 2);
        vm.stopPrank();
    }

    function test_CanOnlyClaimOnce() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // User fulfills the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // A valid maintainer signals for review
        changePrank(bob);
        market.signalReview(requestId, 3);

        // A valid maintainer reviews the request
        market.review(requestId, submissionId, 2);

        // Skip time
        vm.warp(5 weeks);

        // User claims reward
        changePrank(alice);
        market.claim(submissionId);

        // User tries to claim same reward again
        vm.expectRevert("LaborMarket::claim: Already claimed.");
        market.claim(submissionId);

        vm.stopPrank();
    }

    function test_CanOnlyProvideOnce() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // User fulfills the request
        market.provide(requestId, "IPFS://333");

        // Try to fulfill the request again and expect it to revert
        vm.expectRevert("LaborMarket::provide: Already submitted.");
        market.provide(requestId, "IPFS://333");

        vm.stopPrank();
    }

    function test_CannotSelfReview() public {}

    function test_CannotClaimForUngradedSubmission() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // User fulfills the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // A valid maintainer signals for review
        changePrank(bob);
        market.signalReview(requestId, 3);

        // No reviewing happens

        // User attempts to claim the reward, we expect a revert
        changePrank(alice);
        vm.expectRevert("LaborMarket::claim: Not graded.");
        market.claim(submissionId);

        vm.stopPrank();
    }

    function test_CannotClaimOthersSubmission() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // User fulfills the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // A valid maintainer signals for review
        changePrank(bob);
        market.signalReview(requestId, 3);

        // A valid maintainer reviews the request
        market.review(requestId, submissionId, 2);

        // User claims reward
        changePrank(evilUser);
        vm.expectRevert("LaborMarket::claim: Not service provider.");
        market.claim(submissionId);

        vm.stopPrank();
    }

    function test_CannotWithdrawActiveRequest() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        changePrank(bob);
        // User tries to withdraw the request
        vm.expectRevert("LaborMarket::withdrawRequest: Already active.");
        market.withdrawRequest(requestId);

        vm.stopPrank();
    }

    function test_OnlyCreatorCanWithdrawRequest() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // An evil user attempts to withdraw the request
        changePrank(evilUser);
        vm.expectRevert("LaborMarket::withdrawRequest: Not service requester.");
        market.withdrawRequest(requestId);

        vm.stopPrank();
    }

    function test_DeadlinesAreFunctional() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // Skip past signal deadline
        vm.warp(block.timestamp + 100 weeks);

        // Attempt to signal
        changePrank(alice);
        vm.expectRevert("LaborMarket::signal: Signal deadline passed.");
        market.signal(requestId);

        // Go back in time
        vm.warp(block.timestamp - 100 weeks);

        // A valid user signals
        market.signal(requestId);

        // Skip past submission deadline
        vm.warp(block.timestamp + 100 weeks);

        // Attempt to fulfill
        vm.expectRevert("LaborMarket::provide: Submission deadline passed.");
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Go back in time
        vm.warp(block.timestamp - 100 weeks);

        submissionId = market.provide(requestId, "IPFS://333");

        // A valid maintainer signals for review
        changePrank(bob);
        market.signalReview(requestId, 3);

        // Skip past enforcement deadline
        vm.warp(block.timestamp + 100 weeks);

        // Should revert
        vm.expectRevert("LaborMarket::review: Enforcement deadline passed.");
        market.review(requestId, submissionId, 2);

        vm.stopPrank();
    }

    function test_CannotProvideWithoutSignal() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // Attempt to fulfill
        vm.expectRevert("LaborMarket::provide: Not signaled.");
        market.provide(requestId, "IPFS://333");

        vm.stopPrank();
    }

    function test_CannotReviewWithoutSignal() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // User fulfills the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Attempt to review
        vm.expectRevert("LaborMarket::review: Not signaled.");
        market.review(requestId, submissionId, 2);

        vm.stopPrank();
    }
}
