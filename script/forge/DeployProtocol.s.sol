// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {PaymentToken} from "test/forge/Helpers/HelperTokens.sol";

import {BadgerOrganization} from "src/Modules/Badger/BadgerOrganization.sol";
import {Badger} from "src/Modules/Badger/Badger.sol";
import {BadgerScoutInterface} from "src/Modules/Badger/interfaces/BadgerScoutInterface.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import {ScalableLikertEnforcement} from "src/Modules/Enforcement/ScalableLikertEnforcement.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";


// To Deploy: 
// source .env
// forge script DeployProtocol --rpc-url $POLYGON_RPC_URL --private-key ${PRIVATE_KEY} --chain-id 137 --broadcast --verify -vvvv --etherscan-api-key $POLYGONSCAN_API_KEY


struct PaymentTokenInt { 
    bytes32 paymentKey;
    uint256 amount;
}

contract DeployProtocol is Script {
    LaborMarket public marketImplementation;
    LaborMarket public market;
    ReputationModule public reputationModule;
    LaborMarketNetwork public network;
    ScalableLikertEnforcement public enforcement;


    address public capacityToken = address(0);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        LaborMarketConfigurationInterface.BadgePair memory governorPair = LaborMarketConfigurationInterface.BadgePair({
            token: address(0xA873Dad23D357a19ac03CdA4ea3522108D26ebeA),
            tokenId: 6
        });
        
        LaborMarketConfigurationInterface.BadgePair memory creatorPair = LaborMarketConfigurationInterface.BadgePair({
            token: address(0xA873Dad23D357a19ac03CdA4ea3522108D26ebeA),
            tokenId: 3
        });

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: capacityToken,
            _governorBadge: governorPair,
            _creatorBadge: creatorPair
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Create enforcement criteria
        enforcement = new ScalableLikertEnforcement();

        vm.stopBroadcast();
    }
}
