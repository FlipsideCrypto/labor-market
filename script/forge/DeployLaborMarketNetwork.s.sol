// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import { Script } from "forge-std/Script.sol";

import { LaborMarket } from "src/LaborMarket/LaborMarket.sol";
import { LaborMarketNetwork } from "src/Network/LaborMarketNetwork.sol";
import { LaborMarketConfigurationInterface } from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";

// To Deploy: 
// source .env
// forge script DeployLaborMarketNetwork --rpc-url $POLYGON_RPC_URL --private-key ${PRIVATE_KEY} --chain-id 137 --broadcast --verify -vvvv --etherscan-api-key $POLYGONSCAN_API_KEY

contract DeployLaborMarketNetwork is Script {
    LaborMarket public marketImplementation;
    LaborMarketNetwork public network;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy an empty labor market for implementation
        // marketImplementation = new LaborMarket();
        LaborMarketConfigurationInterface.BadgePair memory governorPair = LaborMarketConfigurationInterface.BadgePair({
            token: address(0x854DE1bf96dFBe69FC46f1a888d26934Ad47B77f),
            tokenId: 0
        });
        LaborMarketConfigurationInterface.BadgePair memory creatorPair = LaborMarketConfigurationInterface.BadgePair({
            token: address(0x854DE1bf96dFBe69FC46f1a888d26934Ad47B77f),
            tokenId: 1
        });

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(0),
            _governorBadge: governorPair,
            _creatorBadge: creatorPair
        });

        vm.stopBroadcast();
    }
}
