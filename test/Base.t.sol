// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {Cheats} from "forge-std/Cheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

// Contracts to test
import {LaborMarket} from "src/LaborMarket.sol";
import {MetricNetwork} from "src/MetricNetwork.sol";
import {HelperTokens} from "./Helpers/HelperTokens.sol";

contract ContractTest is PRBTest, Cheats {
    HelperTokens public tokenBank;
    MetricNetwork public metricNetwork;
    LaborMarket public tempMarket;

    uint256 public constant DELEGATE_TOKEN_ID = 0;
    uint256 public constant PARTICIPATION_TOKEN_ID = 1;
    uint256 public constant PAYMENT_TOKEN_ID = 2;

    address public deployer = address(0xDe);

    address public bob = address(0x1);
    address public alice = address(0x2);

    function setUp() public {
        vm.startPrank(deployer);
        metricNetwork = new MetricNetwork(15, 15);

        tokenBank = new HelperTokens("ipfs://000");

        tokenBank.freeMint(bob, DELEGATE_TOKEN_ID, 1);
        tokenBank.freeMint(alice, DELEGATE_TOKEN_ID, 1);
        tokenBank.freeMint(bob, PARTICIPATION_TOKEN_ID, 100);
        tokenBank.freeMint(alice, PARTICIPATION_TOKEN_ID, 100);

        tempMarket = new LaborMarket({
            _metricNetwork: address(metricNetwork),
            _delegateBadge: address(tokenBank),
            _delegateTokenId: DELEGATE_TOKEN_ID,
            _participationBadge: address(tokenBank),
            _participationTokenId: PARTICIPATION_TOKEN_ID,
            _payCurve: address(0x0),
            _enforcementCriteria: address(0x0),
            _repMultiplier: 1,
            _marketUri: "ipfs://111",
            _marketId: 1
        });

        changePrank(alice);
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
            pTokenQ: 100,
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
        tempMarket.review(requestId, submissionId, 10);

        // Claim the reward
        changePrank(alice);
        tempMarket.claim(submissionId);
    }
}
