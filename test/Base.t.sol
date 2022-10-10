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
        vm.stopPrank();
    }

    function test_CreateServiceRequest() public {
        vm.startPrank(bob);

        tempMarket.submitRequest({
            pToken: address(tokenBank),
            pTokenId: PAYMENT_TOKEN_ID,
            pTokenQ: 100,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        assertEq(tempMarket.serviceRequestId(), 1);
        assertEq(tempMarket.getRequest(1).serviceRequester, bob);
        assertEq(tempMarket.getRequest(1).pToken, address(tokenBank));
        vm.stopPrank();
    }
}
