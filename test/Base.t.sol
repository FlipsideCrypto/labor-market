// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {Cheats} from "forge-std/Cheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

// Contracts to test
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";
import {Network} from "src/Network.sol";
import {EnforcementModule} from "src/Modules/Enforcement/EnforcementModule.sol";
import {EnforcementCriteria} from "src/Modules/Enforcement/EnforcementCriteria.sol";
import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {HelperTokens} from "./Helpers/HelperTokens.sol";

contract ContractTest is PRBTest, Cheats {
    HelperTokens public tokenBank;
    MetricNetwork public metricNetwork;
    LaborMarket public tempMarket;
    EnforcementModule public enforcementModule;
    EnforcementCriteria public enforcementCriteria;
    PaymentModule public paymentModule;
    PayCurve public payCurve;

    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant PARTICIPATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;

    address private deployer = address(0xDe);

    address private bob = address(0x1);
    address private alice = address(0x2);

    function setUp() public {
        vm.startPrank(deployer);

        metricNetwork = new MetricNetwork(15, 15);
        enforcementModule = new EnforcementModule();
        enforcementCriteria = new EnforcementCriteria(
            address(enforcementModule)
        );

        paymentModule = new PaymentModule();
        payCurve = new PayCurve();

        tokenBank = new HelperTokens("ipfs://000");

        tokenBank.freeMint(bob, DELEGATE_TOKEN_ID, 1);
        tokenBank.freeMint(alice, DELEGATE_TOKEN_ID, 1);
        tokenBank.freeMint(bob, PARTICIPATION_TOKEN_ID, 1000);
        tokenBank.freeMint(alice, PARTICIPATION_TOKEN_ID, 100);
        tokenBank.freeMint(bob, PAYMENT_TOKEN_ID, 1000e18);

        tempMarket = new LaborMarket({
            _metricNetwork: address(metricNetwork),
            _enforcementModule: address(enforcementModule),
            _paymentModule: address(paymentModule),
            _delegateBadge: address(tokenBank),
            _delegateTokenId: DELEGATE_TOKEN_ID,
            _participationBadge: address(tokenBank),
            _participationTokenId: PARTICIPATION_TOKEN_ID,
            _payCurve: address(payCurve),
            _enforcementCriteria: address(enforcementCriteria),
            _repParticipantMultiplier: 1,
            _repMaintainerMultiplier: 1,
            _marketUri: "ipfs://111",
            _marketId: 1
        });

        changePrank(alice);
        tokenBank.setApprovalForAll(address(tempMarket), true);

        changePrank(bob);
        tokenBank.setApprovalForAll(address(tempMarket), true);

        vm.stopPrank();
    }

    function test_CreateServiceRequest() public {
        // Instrument an admin
        vm.startPrank(bob);

        // Create a request
        uint256 requestId = tempMarket.submitRequest({
            pToken: address(tokenBank),
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
        assertEq(tempMarket.getRequest(requestId).pToken, address(tokenBank));

        // Signal the request
        changePrank(alice);
        tempMarket.signal(requestId);

        // Verify signaling logic
        assertTrue(tempMarket.hasSignaled(requestId, alice));

        assertEq(tokenBank.balanceOf(alice, PARTICIPATION_TOKEN_ID), 85);
        assertEq(
            tokenBank.balanceOf(address(tempMarket), PARTICIPATION_TOKEN_ID),
            15
        );

        // Fulfill the request
        uint256 submissionId = tempMarket.provide(requestId, "IPFS://333");

        // Verify the submission
        // assertEq(tokenBank.balanceOf(alice, PARTICIPATION_TOKEN_ID), 100);
        // assertEq(
        //     tokenBank.balanceOf(address(tempMarket), PARTICIPATION_TOKEN_ID),
        //     0
        // );

        assertEq(tempMarket.getSubmission(submissionId).serviceProvider, alice);
        assertEq(tempMarket.getSubmission(submissionId).uri, "IPFS://333");

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
            pToken: address(tokenBank),
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
            tokenBank.freeMint(user, DELEGATE_TOKEN_ID, 1);
            tokenBank.freeMint(user, PARTICIPATION_TOKEN_ID, 100);

            // Aprove the market
            tokenBank.setApprovalForAll(address(tempMarket), true);

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
            uint256 amt = tempMarket.claim(i + 1);
            totalPaid += amt;
        }

        return assertAlmostEq(totalPaid, 1000e18, 0.000001e18);
    }
}
