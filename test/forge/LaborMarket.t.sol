// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "prb-test/PRBTest.sol";

// Contracts
import { PaymentToken } from "./Helpers/HelperTokens.sol";

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

import {LikertEnforcementCriteria} from "src/Modules/Enforcement/LikertEnforcementCriteria.sol";

import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract LaborMarketTest is PRBTest, StdCheats {
    BadgerOrganization public repToken;
    PaymentToken public payToken;

    Badger public badger;
    BadgerOrganization public badgerMaster;

    LaborMarket public marketImplementation;
    LaborMarket public market;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

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
    address private delegate =
        address(uint160(uint256(keccak256("DELEGATOOOR"))));

    // Events
    /// @dev Announces when a new Labor Market is created through the protocol Factory.
    event LaborMarketCreated(
          address indexed marketAddress
        , address indexed owner
        , address indexed implementation
    );

    /// @notice emitted when labor market parameters are updated.
    event LaborMarketConfigured(
        LaborMarketConfigurationInterface.LaborMarketConfiguration indexed configuration
    );

    /// @notice emitted when a new service request is made.
    event RequestConfigured(
          address indexed requester
        , uint256 indexed requestId
        , string indexed uri
        , address pToken
        , uint256 pTokenQ
        , uint256 signalExp
        , uint256 submissionExp
        , uint256 enforcementExp
    );

    /// @notice emitted when a user signals a service request.
    event RequestSignal(
          address indexed signaler
        , uint256 indexed requestId
        , uint256 signalAmount
    );

    /// @notice emitted when a maintainer signals a review.
    event ReviewSignal(
          address indexed signaler
        , uint256 indexed requestId
        , uint256 indexed quantity
        , uint256 signalAmount
    );

    /// @notice emitted when a service request is withdrawn.
    event RequestWithdrawn(
        uint256 indexed requestId
    );

    /// @notice emitted when a service request is fulfilled.
    event RequestFulfilled(
          address indexed fulfiller
        , uint256 indexed requestId
        , uint256 indexed submissionId
    );

    /// @notice emitted when a service submission is reviewed
    event RequestReviewed(
          address reviewer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 indexed reviewScore
    );

    /// @notice emitted when a service submission is claimed.
    event RequestPayClaimed(
          address indexed claimer
        , uint256 indexed requestId
        , uint256 indexed submissionId
        , uint256 payAmount
        , address to
    );

    /// @notice emitted when a remainder is claimed.
    event RemainderClaimed(
          address indexed claimer
        , uint256 indexed requestId
        , uint256 remainderAmount
    );
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
            _governorBadge: address(repToken),
            _governorTokenId: GOVERNOR_TOKEN_ID
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Create enforcement criteria
        enforcementCriteria = new LikertEnforcementCriteria();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Initialize reputation and roles
        address[] memory delegates = new address[](1);
        delegates[0] = address(reputationModule);
        for (uint256 i=0; i <= GOVERNOR_TOKEN_ID; i++) {
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

        // Make deployer a governor
        repToken.leaderMint(address(deployer), GOVERNOR_TOKEN_ID, 1, "0x");

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
                    maintainer: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: MAINTAINER_TOKEN_ID
                    }),
                    delegate: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: DELEGATE_TOKEN_ID
                    }),
                    reputation: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: REPUTATION_TOKEN_ID
                    }),
                    signalStake: 1e18,
                    submitMin: 1e18,
                    submitMax: 10000e18
                });

        // Create a new labor market
        market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _marketConfiguration: config
            })
        );

        // Approve and mint tokens
        changePrank(deployer);
        repToken.leaderMint(alice, REPUTATION_TOKEN_ID, 100e18, "0x");
        repToken.leaderMint(alice, DELEGATE_TOKEN_ID, 1, "0x");

        changePrank(alice);
        repToken.setApprovalForAll(address(market), true);

        changePrank(deployer);
        repToken.leaderMint(bob, REPUTATION_TOKEN_ID, 1000e18, "0x");
        repToken.leaderMint(bob, DELEGATE_TOKEN_ID, 1, "0x");
        payToken.freeMint(bob, 1_000_000e18);

        repToken.leaderMint(bob, MAINTAINER_TOKEN_ID, 1, "0x");

        changePrank(bob);
        repToken.setApprovalForAll(address(market), true);
        payToken.approve(address(market), 1_000e18);

        changePrank(deployer);
        repToken.leaderMint(bobert, REPUTATION_TOKEN_ID, 1000e18, "0x");
        repToken.leaderMint(bobert, MAINTAINER_TOKEN_ID, 1, "0x");

        changePrank(bobert);
        repToken.setApprovalForAll(address(market), true);

        changePrank(deployer);
        repToken.leaderMint(delegate, DELEGATE_TOKEN_ID, 1, "0x");

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

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function test_CreateServiceRequest() public {
        /**
        | Here we test the creation of a service request
        | A service request contains:
        |  - A payment token (ERC20)
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
            _pToken: address(payToken),
            _pTokenQ: 100e18,
            _signalExp: block.timestamp + 1 hours,
            _submissionExp: block.timestamp + 1 days,
            _enforcementExp: block.timestamp + 1 weeks,
            _requestUri: "ipfs://222"
        });

        // Verify the request was created
        assertEq(market.serviceId(), 1);
        assertEq(market.getRequest(requestId).serviceRequester, bob);
        assertEq(market.getRequest(requestId).pToken, address(payToken));

        // Signal the request
        changePrank(alice);
        market.signal(requestId);

        // Verify signaling logic
        assertTrue(
            market.hasPerformed(requestId, alice, keccak256("hasSignaled"))
        );

        // Fulfill the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        changePrank(bob);
        // Review the request
        market.signalReview(requestId, 1);
        market.review(requestId, submissionId, 2);

        // Claim the reward
        changePrank(alice);

        // Skip to enforcement deadline
        vm.warp(5 weeks);
        market.claim(submissionId, msg.sender, "");
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
                    marketUri: "ipfs://000",
                    modules: LaborMarketConfigurationInterface.Modules({
                        network: address(network),
                        reputation: address(reputationModule),
                        enforcement: address(enforcementCriteria),
                        payment: address(payCurve)
                    }),
                    maintainer: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: MAINTAINER_TOKEN_ID
                    }),
                    delegate: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: DELEGATE_TOKEN_ID
                    }),
                    reputation: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: REPUTATION_TOKEN_ID
                    }),
                    signalStake: 1e18,
                    submitMin: 1e18,
                    submitMax: 10000e18
                });

        // Create 10 markets
        for (uint256 i; i <= 10; ++i) {
            changePrank(deployer);
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
                    _marketConfiguration: config
                })
            );

            changePrank(bob);
            payToken.approve(address(market), 1_000e18);
            uint256 requestId = createSimpleRequest(market);

            changePrank(alice);
            market.signal(requestId);
            uint256 submissionId = market.provide(requestId, "IPFS://333");

            changePrank(bob);
            market.signalReview(requestId, 1);
            
            market.review(requestId, submissionId, 2);

            changePrank(alice);
            vm.warp(block.timestamp + 5 weeks);
            market.claim(submissionId, msg.sender, "");
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
            (100e18 - market.getConfiguration().signalStake)
        );

        // Fulfill the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        changePrank(bob);

        // Review the request
        market.signalReview(requestId, 3);

        // Verify that Maintainers's reputation is locked
        uint256 signalStake = market.getConfiguration().signalStake;

        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            (1000e18 - signalStake * 3)
        );

        market.review(requestId, submissionId, 2);

        // Verify that the maintainer gets returned some reputation
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            (1000e18 - signalStake * 2)
        );

        // Claim the reward
        changePrank(alice);

        // Skip to enforcement deadline
        vm.warp(5 weeks);
        market.claim(submissionId, msg.sender, "");

        // Verify that Alice's reputation is unlocked
        assertEq(
            reputationModule.getAvailableReputation(address(market), alice),
            100e18
        );
    }

    function test_VerifyAllEmittedEvents() public {
        vm.startPrank(deployer);

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
                    maintainer: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: MAINTAINER_TOKEN_ID
                    }),
                    delegate: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: DELEGATE_TOKEN_ID
                    }),
                    reputation: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: REPUTATION_TOKEN_ID
                    }),
                    signalStake: 1e18,
                    submitMin: 1e18,
                    submitMax: 10000e18
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
                _marketConfiguration: config
            })
        );

        changePrank(bob);
        payToken.approve(address(market), 1_000e18);

        // Verify service request creation event
        address pToken = address(payToken);
        uint256 pTokenQ = 1000e18;
        uint256 signalExp = block.timestamp + 1 hours;
        uint256 submissionExp = block.timestamp + 1 days;
        uint256 enforcementExp = block.timestamp + 1 weeks;
        string memory requestUri = "ipfs://222";
        uint256 serviceRequestId;

        vm.expectEmit(true, false, true, true);
        emit RequestConfigured(
            address(bob),
            serviceRequestId,
            requestUri,
            pToken,
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
        emit ReviewSignal(address(bob), requestId, 3, 3e18);

        changePrank(bob);
        market.signalReview(requestId, 3);

        // Verify submission events
        vm.expectEmit(true, true, true, true);
        emit RequestFulfilled(address(alice), requestId, requestId + 1);

        changePrank(alice);
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Verify reviewing events
        vm.expectEmit(true, true, true, true);
        emit RequestReviewed(address(bob), requestId, submissionId, 2);

        changePrank(bob);
        market.review(requestId, submissionId, 2);

        // // Verify claiming events
        vm.expectEmit(true, true, true, true);
        emit RequestPayClaimed(
            address(alice),
            requestId,
            submissionId,
            799999999973870935009, // (100e18 * 0.8)
            address(alice)
        );

        changePrank(alice);
        vm.warp(block.timestamp + 5 weeks);
        market.claim(submissionId, address(alice), "");

        // // Verify withdrawing request event
        changePrank(bob);

        payToken.approve(address(market), 1_000e18);
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
                    maintainer: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: MAINTAINER_TOKEN_ID
                    }),
                    delegate: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: DELEGATE_TOKEN_ID
                    }),
                    reputation: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: REPUTATION_TOKEN_ID
                    }),
                    signalStake: 1e18,
                    submitMin: 1e18,
                    submitMax: 10000e18
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
        market.claim(submissionId, msg.sender, "");

        // User tries to claim same reward again
        vm.expectRevert("LaborMarket::claim: Already claimed.");
        market.claim(submissionId, msg.sender, "");

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

    function test_CannotClaimForUnReviewedSubmission() public {
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
        vm.expectRevert("LaborMarket::claim: Not reviewed.");
        market.claim(submissionId, msg.sender, "");

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
        market.claim(submissionId, msg.sender, "");

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

        // Another delegate attempts to withdraw the request
        changePrank(delegate);
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

    function test_TwoReviewers() public {
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

        // Another maintainer signals
        changePrank(bobert);
        market.signalReview(requestId, 3);

        // A valid maintainer reviews the request
        changePrank(bob);
        market.review(requestId, submissionId, 2);

        // Another maintainer reviews the request
        changePrank(bobert);
        market.review(requestId, submissionId, 0);

        // Scores
        assertEq(market.getSubmission(submissionId).scores[0], 2);
        assertEq(market.getSubmission(submissionId).scores[1], 0);

        changePrank(alice);
        vm.warp(123 weeks);

        // User claims reward
        // Score should average to 1 meaning it falls in the 20% bucket and should receive 20% of the reward
        uint256 qClaimed = market.claim(submissionId, alice, "");
        assertAlmostEq(qClaimed, 200e18, 0.000001e18);

        vm.stopPrank();
    }

    function test_NotEnoughSubmissionsToReview() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // User fulfills the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Check maintainers (bob) reputation
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18
        );

        // A valid maintainer signals for review (4 of them)
        changePrank(bob);
        market.signalReview(requestId, 4);

        uint256 signalStake = market.getConfiguration().signalStake;

        // 4e18 of rep should be locked
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18 - signalStake * 4
        );

        // A valid maintainer reviews the request
        market.review(requestId, submissionId, 2);

        // Should unlock 1e18 of rep
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18 - signalStake * 3
        );

        // Skip forward in time
        vm.warp(123 weeks);

        // Reviewer reclaims their signal stake
        market.retrieveReputation(requestId);

        // Should have full rep again
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18
        );

        vm.stopPrank();
    }

    function test_CannotRetrieveReputationIfThereWasOpportunityToReview()
        public
    {
        vm.startPrank(bob);
        uint256 submissionId;

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid maintainer signals for review (4 of them)
        changePrank(bob);
        market.signalReview(requestId, 4);

        for (uint256 i; i < 25; i++) {
            changePrank(deployer);
            address user = address(uint160(i + 123));
            repToken.leaderMint(user, REPUTATION_TOKEN_ID, 100e18, "0x");
            // A valid user signals
            changePrank(user);
            market.signal(requestId);

            // User fulfills the request
            submissionId = market.provide(requestId, "IPFS://333");
        }

        // A valid maintainer reviews the request
        changePrank(bob);
        market.review(requestId, submissionId, 2);

        // Skip forward in time
        vm.warp(123 weeks);

        // Reviewer reclaims their signal stake
        vm.expectRevert(
            "LaborMarket::retrieveReputation: Insufficient reviews."
        );
        market.retrieveReputation(requestId);

        vm.stopPrank();
    }

    function test_CannotRetrieveReputationTwice() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(market);

        // A valid user signals
        changePrank(alice);
        market.signal(requestId);

        // User fulfills the request
        uint256 submissionId = market.provide(requestId, "IPFS://333");

        // Check maintainers (bob) reputation
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18
        );

        // A valid maintainer signals for review (4 of them)
        changePrank(bob);
        market.signalReview(requestId, 4);

        uint256 signalStake = market.getConfiguration().signalStake;

        // 4e18 of rep should be locked
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18 - signalStake * 4
        );

        // A valid maintainer reviews the request
        market.review(requestId, submissionId, 2);

        // Should unlock 3/4 of rep staked
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18 - signalStake * 3
        );

        // Skip forward in time
        vm.warp(123 weeks);

        // Reviewer reclaims their signal stake
        market.retrieveReputation(requestId);

        // Should have full rep again
        assertEq(
            reputationModule.getAvailableReputation(address(market), bob),
            1000e18
        );

        // Reviewer reclaims their signal stake again
        vm.expectRevert(
            "LaborMarket::retrieveReputation: No reputation to retrieve."
        );
        market.retrieveReputation(requestId);

        vm.stopPrank();
    }
}
