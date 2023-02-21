// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "prb-test/PRBTest.sol";

// Contracts
import {PaymentToken} from "../Helpers/HelperTokens.sol";
import { BadgerOrganization } from "src/Modules/Badger/BadgerOrganization.sol";
import { Badger } from "src/Modules/Badger/Badger.sol";
import { BadgerScoutInterface } from "src/Modules/Badger/interfaces/BadgerScoutInterface.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import { ConstantLikertEnforcement } from "src/Modules/Enforcement/ConstantLikertEnforcement.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract ReputationModuleTest is PRBTest, StdCheats {
    Badger public badger;
    BadgerOrganization public badgerMaster;

    BadgerOrganization public repToken;
    PaymentToken public payToken;

    LaborMarket public marketImplementation;
    LaborMarket public market;

    ConstantLikertEnforcement public enforcement;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;


    // Define the tokenIds for ERC1155
    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;
    uint256 private constant MAINTAINER_TOKEN_ID = 3;
    uint256 private constant GOVERNOR_TOKEN_ID = 4;
    uint256 private constant CREATOR_TOKEN_ID = 5;
    uint256 private constant REPUTATION_DECAY_RATE = 0;
    uint256 private constant REPUTATION_DECAY_INTERVAL = 0;

    // Deployer
    address private deployer = address(0xDe);

    // Maintainer
    address private bob = address(0x1);

    // Maintainer 2
    address private bobert = address(0x11);

    // User
    address private alice = address(0x2);

    // Evil user
    address private evilUser =
        address(uint160(uint256(keccak256("EVIL_USER"))));

    // Alt delegate
    address private delegate =
        address(uint160(uint256(keccak256("DELEGATOOOR"))));


    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        payToken = new PaymentToken(deployer);

        // Create badger factory
        badgerMaster = new BadgerOrganization();
        badger = new Badger(address(badgerMaster));

        // Create reputation and role token contract
        repToken = BadgerOrganization(
            payable(badger.createOrganization(
                address(badgerMaster),
                address(deployer),
                "ipfs://000",
                "ipfs://000",
                "MDAO",
                "MDAO"
            )
        ));

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(payToken),
            _governorBadge: LaborMarketConfigurationInterface.BadgePair({
                token: address(repToken),
                tokenId: GOVERNOR_TOKEN_ID
            }),
            _creatorBadge: LaborMarketConfigurationInterface.BadgePair({
                token: address(repToken),
                tokenId: CREATOR_TOKEN_ID
            })
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Initialize reputation and roles
        address[] memory delegates = new address[](1);
        delegates[0] = address(reputationModule);
        for (uint256 i=0; i <= CREATOR_TOKEN_ID; i++) {
            repToken.setBadge(
                i,
                false,
                true,
                address(this),
                "ipfs/",
                BadgerScoutInterface.PaymentToken({
                    paymentKey: bytes32(0),
                    amount: 0
                }),
                delegates
            );
        }

        // Make deployer a governor and creator
        repToken.leaderMint(address(deployer), GOVERNOR_TOKEN_ID, 1, "0x");
        repToken.leaderMint(address(deployer), CREATOR_TOKEN_ID, 1, "0x");

        enforcement = new ConstantLikertEnforcement();

        bytes32 criteria = "";

        // Create a new labor market configuration for likert
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory likertConfig = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    marketUri: "ipfs://000",
                    owner: address(deployer),
                    modules: LaborMarketConfigurationInterface.Modules({
                        network: address(network),
                        reputation: address(reputationModule),
                        enforcement: address(enforcement),
                        enforcementKey: criteria
                    }),
                    maintainerBadge: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: MAINTAINER_TOKEN_ID
                    }),
                    delegateBadge: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: DELEGATE_TOKEN_ID
                    }),
                    reputationBadge: LaborMarketConfigurationInterface.BadgePair({
                        token: address(repToken),
                        tokenId: REPUTATION_TOKEN_ID
                    }),
                    reputationParams: LaborMarketConfigurationInterface.ReputationParams({
                        rewardPool: 5000,
                        provideStake: 5,
                        reviewStake: 5,
                        submitMin: 5,
                        submitMax: 10000e18
                    })
                });

        // Create a new likert labor market
        market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _configuration: likertConfig
            })
        );

        // Approve and mint tokens
        repToken.leaderMint(alice, REPUTATION_TOKEN_ID, 100e18, "0x");
        repToken.leaderMint(alice, DELEGATE_TOKEN_ID, 1, "0x");

        changePrank(alice);
        repToken.setApprovalForAll(address(market), true);

        changePrank(deployer);
        repToken.leaderMint(bob, REPUTATION_TOKEN_ID, 100000e18, "0x");
        repToken.leaderMint(bob, DELEGATE_TOKEN_ID, 1, "0x");
        payToken.freeMint(bob, 1_000_000e18);
        repToken.leaderMint(bob, MAINTAINER_TOKEN_ID, 1, "0x");

        changePrank(bob);
        repToken.setApprovalForAll(address(market), true);
        payToken.approve(address(market), 1_000e18);

        changePrank(deployer);
        repToken.leaderMint(bobert, REPUTATION_TOKEN_ID, 1000e18, "0x");
        repToken.leaderMint(bobert, MAINTAINER_TOKEN_ID, 1, "0x");

        changePrank(bobert);
        repToken.setApprovalForAll(address(market), true);

        changePrank(deployer);
        repToken.leaderMint(delegate, DELEGATE_TOKEN_ID, 1, "0x");

        vm.stopPrank();
    }

    function createSimpleRequest(LaborMarket simpleMarket)
        internal
        returns (uint256)
    {
        uint256 rid = simpleMarket.submitRequest({
            _pToken: address(payToken),
            _pTokenQ: 1000e18,
            _signalExp: block.timestamp + 1 hours,
            _submissionExp: block.timestamp + 1 days,
            _enforcementExp: block.timestamp + 1 weeks,
            _requestUri: "ipfs://222"
        });

        return rid;
    }

    function test_CanSetDecayConfig() public {
        vm.startPrank(deployer);

        network.setReputationDecay(
            address(reputationModule),
            address(repToken),
            REPUTATION_TOKEN_ID,
            10,
            5000,
            block.timestamp
        );

        (uint256 decay, uint256 interval, uint256 lastDecay) = reputationModule.decayConfig(
            address(repToken),
            REPUTATION_TOKEN_ID
        );

        assertEq(decay, 10, "Decay should be 10");
        assertEq(interval, 5000, "Interval should be 5000");
        assertEq(lastDecay, block.timestamp, "Last decay should be now");

        vm.stopPrank();
    }

    function test_ReputationDecayOneInterval() public {
        vm.startPrank(deployer);

        repToken.leaderMint(bob, GOVERNOR_TOKEN_ID, 1, "0x");
        repToken.leaderMint(delegate, GOVERNOR_TOKEN_ID, 1, "0x");

        network.setReputationDecay(
            address(reputationModule),
            address(repToken),
            REPUTATION_TOKEN_ID,
            10,
            5000,
            block.timestamp
        );

        changePrank(bob);
        payToken.approve(address(market), 10000e18);
        uint256 requestId = market.submitRequest({
            _pToken: address(payToken),
            _pTokenQ: 100e18,
            _signalExp: block.timestamp + 4 weeks,
            _submissionExp: block.timestamp + 5 weeks,
            _enforcementExp: block.timestamp + 6 weeks,
            _requestUri: "ipfs://222"
        });

        // // A valid user signals
        changePrank(alice);
        uint256 balanceBefore = repToken.balanceOf(address(alice), REPUTATION_TOKEN_ID);

        vm.warp(2 hours);
        uint256 expectedDecay = reputationModule.getPendingDecay(
            address(market),
            address(alice)
        );

        market.signal(requestId);

        assertEq(
            repToken.balanceOf(address(alice), REPUTATION_TOKEN_ID),
            balanceBefore - expectedDecay - 5
        );

        vm.stopPrank();
    }

    function test_ReputationDecayMaxDecay() public {
        vm.startPrank(deployer);

        address newGuy = address(0xffff);

        repToken.leaderMint(bob, GOVERNOR_TOKEN_ID, 1, "0x");
        repToken.leaderMint(delegate, GOVERNOR_TOKEN_ID, 1, "0x");
        repToken.leaderMint(newGuy, REPUTATION_TOKEN_ID, 1000, "0x");

        network.setReputationDecay(
            address(reputationModule),
            address(repToken),
            REPUTATION_TOKEN_ID,
            10,
            5000,
            block.timestamp
        );

        changePrank(bob);
        payToken.approve(address(market), 10000e18);

        market.submitRequest({
            _pToken: address(payToken),
            _pTokenQ: 100e18,
            _signalExp: block.timestamp + 99 weeks,
            _submissionExp: block.timestamp + 100 weeks,
            _enforcementExp: block.timestamp + 101 weeks,
            _requestUri: "ipfs://222"
        });

        // // A valid user signals
        changePrank(newGuy);

        vm.warp(10 weeks);

        assertEq(
            reputationModule.getAvailableReputation(address(market), address(newGuy)),
            0
        );

        vm.stopPrank();
    }

    function test_CanFreezeReputation() public {
        vm.startPrank(deployer);

        network.setReputationDecay(
            address(reputationModule),
            address(repToken),
            REPUTATION_TOKEN_ID,
            10,
            5000,
            block.timestamp
        );

        changePrank(bob);

        uint256 balanceBefore = reputationModule.getAvailableReputation(address(market), address(bob));

        reputationModule.freezeReputation(
            address(bob),
            address(repToken),
            REPUTATION_TOKEN_ID,
            1000000
        );

        assertEq(
            reputationModule.getAvailableReputation(address(market), address(bob)),
            0
        );

        vm.warp(300 weeks);

        assertLt(
            reputationModule.getAvailableReputation(address(market), address(bob)),
            balanceBefore
        );

        vm.stopPrank();
    }
}
