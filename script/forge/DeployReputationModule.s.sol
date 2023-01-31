// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";

import { LaborMarket } from "src/LaborMarket/LaborMarket.sol";
import { LaborMarketNetwork } from "src/Network/LaborMarketNetwork.sol";
import { LaborMarketConfigurationInterface } from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import { ReputationModule } from "src/Modules/Reputation/ReputationModule.sol";

// To Deploy: 
// source .env
// forge script DeployReputationModule --rpc-url $POLYGON_RPC_URL --private-key ${PRIVATE_KEY} --chain-id 137 --broadcast --verify -vvvv --etherscan-api-key $POLYGONSCAN_API_KEY

contract DeployReputationModule is Script {
    LaborMarket public marketImplementation;
    LaborMarketNetwork public network;
    ReputationModule public reputationModule;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        reputationModule = new ReputationModule(address(0x57bD82488017e1b32b3BeD03389fBCB6D69750b8));

        vm.stopBroadcast();
    }
}
