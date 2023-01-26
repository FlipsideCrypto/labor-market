// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

import {PaymentToken} from "test/forge/Helpers/HelperTokens.sol";

import { BadgerOrganization } from "src/Modules/Badger/BadgerOrganization.sol";
import { Badger } from "src/Modules/Badger/Badger.sol";
import { BadgerScoutInterface } from "src/Modules/Badger/interfaces/BadgerScoutInterface.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import {LikertEnforcementCriteria} from "src/Modules/Enforcement/LikertEnforcementCriteria.sol";

import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

// Assumes:
// RPC_URL= ABC
// PRIVATE_KEY= DEF
// ETHERSCAN_API_KEY= GHI

struct PaymentTokenInt { 
    bytes32 paymentKey;
    uint256 amount;
}

contract X is Script {
    LaborMarket public marketImplementation;
    LaborMarket public market;

    ReputationModule public reputationModule;

    LaborMarketNetwork public network;

    LikertEnforcementCriteria public enforcementCriteria;
    PayCurve public payCurve;

    address public capacityToken = address(0);
    
    address public governorBadgeAddress = address(0xA873Dad23D357a19ac03CdA4ea3522108D26ebeA);
    uint256 public governorBadgeTokenId = 3;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: capacityToken,
            _governorBadge: governorBadgeAddress,
            _governorTokenId: governorBadgeTokenId
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Create enforcement criteria
        enforcementCriteria = new LikertEnforcementCriteria();

        // Create a new pay curve
        payCurve = new PayCurve();

        vm.stopBroadcast();
    }
}
