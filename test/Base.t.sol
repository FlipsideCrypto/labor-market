// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Cheats} from "forge-std/Cheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

contract ContractTest is PRBTest, Cheats {
    function setUp() public {}

    function testExample() public {
        console.log("Hello World");
        assertTrue(true);
    }
}
