// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {Cheats} from "forge-std/Cheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

// Contracts
import {MockERC1155, MockERC20} from "./Helpers/HelperTokens.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {EnforcementModule} from "src/Modules/Enforcement/EnforcementModule.sol";
import {EnforcementCriteria} from "src/Modules/Enforcement/EnforcementCriteria.sol";

import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {ReputationToken} from "src/Modules/Reputation/ReputationToken.sol";

import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";
import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";

contract ContractTest is PRBTest, Cheats {
    MockERC1155 public baseRepToken;
    MockERC20 public capToken;

    LaborMarket public implementation;
    LaborMarket public tempMarket;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    EnforcementModule public enforcementModule;
    EnforcementCriteria public enforcementCriteria;
    PaymentModule public paymentModule;
    PayCurve public payCurve;

    ReputationToken public reputationTokenMaster;
    ReputationToken public reputationToken;
    ReputationModule public reputationModule;

    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;
    uint256 private constant REPUTATION_DECAY_RATE = 0;
    uint256 private constant REPUTATION_DECAY_INTERVAL = 0;

    address private deployer = address(0xDe);

    address private bob = address(0x1);
    address private alice = address(0x2);

    event LaborMarketCreated(
        address indexed organization,
        address indexed owner,
        address indexed implementation
    );

    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        baseRepToken = new MockERC1155("ipfs://000");
        capToken = new MockERC20();

        // Deploy an empty labor market for implementation
        implementation = new LaborMarket();

        // Deploy a labor market factory
        factory = new LaborMarketFactory(address(implementation));

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(implementation),
            _capacityImplementation: address(capToken)
        });

        // Create enforcement criteria
        enforcementCriteria = new EnforcementCriteria();

        // Create a payment module
        paymentModule = new PaymentModule();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Create a reputation module
        reputationModule = new ReputationModule(address(network));

        // Deploy an empty reputation token for cloning.
        reputationTokenMaster = new ReputationToken();

        // Create a reputation token with the Mock1155
        reputationToken = ReputationToken(
            reputationModule.createReputationToken(
                address(reputationTokenMaster),
                address(baseRepToken),
                REPUTATION_TOKEN_ID,
                REPUTATION_DECAY_RATE,
                REPUTATION_DECAY_INTERVAL
            )
        );

        // Create the ReputationConfig for the Labor Market
        ReputationModuleInterface.ReputationMarketConfig 
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationToken: address(reputationToken),
                    signalStake: 0,
                    providerThreshold: 0,
                    maintainerThreshold: 0 
                });

        // Create a new labor market
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(baseRepToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        tempMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(implementation),
                _deployer: deployer,
                _configuration: config
            })
        );

        // Approve and mint tokens
        changePrank(alice);
        baseRepToken.freeMint(alice, REPUTATION_TOKEN_ID, 100e18);
        baseRepToken.freeMint(alice, DELEGATE_TOKEN_ID, 1);
        baseRepToken.setApprovalForAll(address(tempMarket), true);

        changePrank(bob);
        baseRepToken.freeMint(bob, REPUTATION_TOKEN_ID, 1000e18);
        baseRepToken.freeMint(bob, DELEGATE_TOKEN_ID, 1);
        baseRepToken.setApprovalForAll(address(tempMarket), true);

        vm.stopPrank();
    }

    function test_CreateServiceRequest() public {
        // Instrument an admin
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = tempMarket.submitRequest({
            pToken: address(baseRepToken),
            pTokenId: PAYMENT_TOKEN_ID,
            pTokenQ: 100e18,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        // Verify the request was created
        assertEq(tempMarket.serviceRequestId(), 1);
        assertEq(tempMarket.getRequest(requestId).serviceRequester, bob);
        assertEq(tempMarket.getRequest(requestId).pToken, address(baseRepToken));

        // Signal the request
        changePrank(alice);
        tempMarket.signal(requestId);

        // Verify signaling logic
        assertTrue(tempMarket.submissionSignals(requestId, alice));

        // Fulfill the request
        uint256 submissionId = tempMarket.provide(requestId, "IPFS://333");

        changePrank(bob);
        // Review the request
        tempMarket.signalReview(requestId);
        tempMarket.review(requestId, submissionId, 2);

        // Claim the reward
        changePrank(alice);

        // Skip to enforcement deadline
        vm.warp(5 weeks);
        tempMarket.claim(submissionId);
    }

    function test_ExampleEnforcementTest() public {
        /**
        | pTokens: 1000
        | Participants: 112
        | Likert ratings: (1, BAD), (2, OK), (3, GOOD)
        | Bucket distribution: (1, 66), (2, 36), (3, 10)
        | Payout distribution: (1, 0), (2, 20%), (3, 80%)
        | Expected Tokens per person per bucket: (1, 0), (2, 5.5), (3, 80)
        */

        vm.startPrank(bob);

        // Create a request
        uint256 requestId = tempMarket.submitRequest({
            pToken: address(baseRepToken),
            pTokenId: PAYMENT_TOKEN_ID,
            pTokenQ: 100e18,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        // Signal the request on 112 accounts
        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Mint required tokens
            baseRepToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            baseRepToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);

            // Aprove the market
            baseRepToken.setApprovalForAll(address(tempMarket), true);

            tempMarket.signal(requestId);
            tempMarket.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

        tempMarket.signalReview(requestId);

        for (uint256 i; i < 113; i++) {
            if (i < 67) {
                // BAD
                tempMarket.review(requestId, i + 1, 0);
            } else if (i < 103) {
                // OK
                tempMarket.review(requestId, i + 1, 1);
            } else {
                // GOOD
                tempMarket.review(requestId, i + 1, 2);
            }
        }

        uint256 totalPaid;

        vm.warp(5 weeks);

        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            totalPaid += tempMarket.claim(i + 1);
        }

        assertAlmostEq(totalPaid, 1000e18, 0.000001e18);
    }

    function test_CreateMultipleMarkets() public {
        vm.startPrank(deployer);

        ReputationModuleInterface.ReputationMarketConfig 
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationToken: address(reputationToken),
                    signalStake: 0,
                    providerThreshold: 0,
                    maintainerThreshold: 0 
                });

        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(enforcementCriteria),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(baseRepToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        for (uint256 i; i < 10; ++i) {
            vm.expectEmit(false, true, true, true);
            emit LaborMarketCreated(
                address(tempMarket),
                deployer,
                address(implementation)
            );
            tempMarket = LaborMarket(
                network.createLaborMarket({
                    _implementation: address(implementation),
                    _deployer: deployer,
                    _configuration: config
                })
            );

            changePrank(bob);
            uint256 requestId = tempMarket.submitRequest({
                pToken: address(baseRepToken),
                pTokenId: PAYMENT_TOKEN_ID,
                pTokenQ: 100e18,
                signalExp: block.timestamp + 1 hours,
                submissionExp: block.timestamp + 1 days,
                enforcementExp: block.timestamp + 1 weeks,
                requestUri: "ipfs://222"
            });

            changePrank(alice);
            tempMarket.signal(requestId);
            tempMarket.provide(requestId, "IPFS://333");

            changePrank(bob);
            tempMarket.signalReview(requestId);
            tempMarket.review(requestId, 1, 2);

            changePrank(alice);
            vm.warp(block.timestamp + 5 weeks);
            tempMarket.claim(requestId);
        }
        vm.stopPrank();
    }

    function test_ReputationalChangesBasedOnActions() public {
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = tempMarket.submitRequest({
            pToken: address(baseRepToken),
            pTokenId: PAYMENT_TOKEN_ID,
            pTokenQ: 100e18,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        // Signal the request
        changePrank(alice);
        tempMarket.signal(requestId);

        // Verify that Alice's reputation is locked
        assertEq(
            reputationModule.getAvailableReputation(
                address(tempMarket),
                alice
            ),
            (100e18 - reputationModule.getSignalStake(address(tempMarket)))
        );

        // Fulfill the request
        uint256 submissionId = tempMarket.provide(requestId, "IPFS://333");

        assertEq(
            reputationModule.getAvailableReputation(
                address(tempMarket),
                alice
            ),
            100e18
        );

        // Verify that Alice's reputation is unlocked

        changePrank(bob);

        // Review the request
        tempMarket.signalReview(requestId);

        // Verify that Maintainers's reputation is locked
        assertEq(
            reputationModule.getAvailableReputation(
                address(tempMarket),
                bob
            ),
            (1000e18 - reputationModule.getSignalStake(address(tempMarket)))
        );

        tempMarket.review(requestId, submissionId, 2);

        // Claim the reward
        changePrank(alice);

        // Skip to enforcement deadline
        vm.warp(5 weeks);
        tempMarket.claim(submissionId);
    }
}
