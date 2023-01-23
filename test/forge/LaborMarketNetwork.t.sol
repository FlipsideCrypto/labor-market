// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "prb-test/PRBTest.sol";

// Contracts
import {AnyReputationToken} from "./Helpers/HelperTokens.sol";

import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";

contract LaborMarketNetworkTest is PRBTest, StdCheats {
    AnyReputationToken public repToken;

    LaborMarket public marketImplementation;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    // Deployer
    address private deployer = address(0xDe);

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Generic reputation token
        repToken = new AnyReputationToken("reputation nation", deployer);

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(address(0)),
            _governorBadge: address(repToken),
            _governorTokenId: 1
        });
    }

    function test_ChangeCapacityImplementation() public {
        // Deploy a new capacity implementation
        address newCapacityImplementation = address(
            new AnyReputationToken("new capacity", deployer)
        );

        // Change the capacity implementation
        network.setCapacityImplementation(newCapacityImplementation);

        // Check that the new capacity implementation is set
        assertEq(address(network.capacityToken()), newCapacityImplementation);
    }
}
