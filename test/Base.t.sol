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

import {EnforcementModule} from "src/Modules/Enforcement/EnforcementModule.sol";
import {EnforcementCriteria} from "src/Modules/Enforcement/EnforcementCriteria.sol";
import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

contract ContractTest is PRBTest, Cheats {
    ReputationToken public repToken;
    CapacityToken public capToken;

    LaborMarket public implementation;
    LaborMarket public tempMarket;

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

    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        repToken = new ReputationToken("ipfs://000");
        capToken = new CapacityToken();

        // Deploy an empty labor market for implementation
        implementation = new LaborMarket();

        // Deploy a labor market factory
        factory = new LaborMarketFactory(address(implementation));

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(implementation),
            _reputationImplementation: address(repToken),
            _capacityImplementation: address(capToken),
            _baseSignalStake: 1e18,
            _baseProviderThreshold: 10e18,
            _baseMaintainerThreshold: 100e18,
            _reputationTokenId: REPUTATION_TOKEN_ID,
            _reputationDecayRate: 0,
            _reputationDecayInterval: 0
        });

        // Create enforcement criteria
        enforcementCriteria = new EnforcementCriteria(address(0x0));

        // Create a payment module
        paymentModule = new PaymentModule();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Create a new labor market
        tempMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(implementation),
                _deployer: deployer,
                _enforcementModule: address(enforcementCriteria),
                _paymentModule: address(payCurve),
                _delegateBadge: address(repToken),
                _delegateTokenId: DELEGATE_TOKEN_ID,
                _participationBadge: address(repToken),
                _participationTokenId: REPUTATION_TOKEN_ID,
                _repParticipantMultiplier: 1,
                _repMaintainerMultiplier: 1,
                _marketUri: "ipfs://777"
            })
        );

        // Approve and mint tokens
        changePrank(alice);
        repToken.freeMint(alice, REPUTATION_TOKEN_ID, 100e18);
        repToken.freeMint(alice, DELEGATE_TOKEN_ID, 1);
        repToken.setApprovalForAll(address(tempMarket), true);

        changePrank(bob);
        repToken.freeMint(bob, REPUTATION_TOKEN_ID, 100e18);
        repToken.freeMint(bob, DELEGATE_TOKEN_ID, 1);
        repToken.setApprovalForAll(address(tempMarket), true);

        vm.stopPrank();
    }

    function test_CreateServiceRequest() public {
        // Instrument an admin
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = tempMarket.submitRequest({
            pToken: address(repToken),
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
        assertEq(tempMarket.getRequest(requestId).pToken, address(repToken));

        // Signal the request
        changePrank(alice);
        tempMarket.signal(requestId);

        // Verify signaling logic
        assertTrue(tempMarket.hasSignaled(requestId, alice));

        // Fulfill the request
        uint256 submissionId = tempMarket.provide(requestId, "IPFS://333");

        changePrank(bob);
        // Review the request
        tempMarket.review(requestId, submissionId, 2);

        // Claim the reward
        changePrank(alice);
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
            pToken: address(repToken),
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
            repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);

            // Aprove the market
            repToken.setApprovalForAll(address(tempMarket), true);

            tempMarket.signal(requestId);
            tempMarket.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

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

        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            totalPaid += tempMarket.claim(i + 1);
        }

        //assertAlmostEq(totalPaid, 1000e18, 0.000001e18);
        // Stack2deep
    }
}
