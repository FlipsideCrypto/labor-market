// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

// To Deploy: 
// source .env
// forge script DeployLaborMarketVersion --rpc-url $POLYGON_RPC_URL --private-key ${PRIVATE_KEY} --chain-id 137 --broadcast --verify -vvvv --etherscan-api-key $POLYGONSCAN_API_KEY

contract DeployLaborMarketVersion is Script {
    LaborMarket public marketImplementation;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        vm.stopBroadcast();
    }
}
