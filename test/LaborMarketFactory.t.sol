// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "@prb/test/PRBTest.sol";

// Contracts
import {AnyReputationToken} from "./Helpers/HelperTokens.sol";

import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketVersionsInterface} from "src/Network/interfaces/LaborMarketVersionsInterface.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";
import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

contract LaborMarketFactoryTest is PRBTest, StdCheats {
    AnyReputationToken public repToken;

    LaborMarket public marketImplementation;
    LaborMarket public market;

    LaborMarketFactory public factory;

    // Deployer
    address private deployer = address(0xDe);

    struct Version {
        address owner;
        bytes32 licenseKey;
        uint256 amount;
        bool locked;
    }

    event VersionUpdated(
        address indexed implementation,
        Version indexed version
    );

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Generic reputation token
        repToken = new AnyReputationToken("reputation nation", deployer);

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy a labor market factory
        factory = new LaborMarketFactory(address(marketImplementation));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function test_SetAndVerifyVersion() public {
        vm.startPrank(deployer);
        vm.expectEmit(true, false, false, true);
        emit VersionUpdated(
            address(marketImplementation),
            Version(msg.sender, 0, 0, true)
        );
        factory.setVersion({
            _implementation: address(marketImplementation),
            _owner: address(0xDe1),
            _tokenAddress: address(0),
            _tokenId: 1,
            _amount: 0,
            _locked: true
        });

        assertEq(
            bytes32(
                0xe99467d027c1d99b544d929e378c5ecfc6b0e521f7cc79d93719111138a166eb
            ),
            factory.getVersionKey(address(marketImplementation))
        );

        assertEq(
            factory.getLicenseKey(
                factory.getVersionKey(address(marketImplementation)),
                deployer
            ),
            bytes32(
                0x7ad87180ebfd534b0d6e2564b5db772db37925b93a23dce0d0c2d549e9893141
            )
        );
        (address newVersionOwner, , , ) = factory.versions(
            address(marketImplementation)
        );

        assertEq(newVersionOwner, address(0xDe1));

        vm.stopPrank();
    }

    function test_ExecTransaction() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(0xaa));
        factory.execTransaction(address(marketImplementation), "0x", 0);

        vm.prank(deployer);
        factory.execTransaction(address(0), "", 0);
    }

    function test_OnERC1155Receive() public {
        vm.prank(deployer);
        repToken.freeMint(address(factory), 0, 1);
    }
}
