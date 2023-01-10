// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Testing imports
import {StdCheats} from "forge-std/StdCheats.sol";
import {console} from "forge-std/console.sol";
import {PRBTest} from "prb-test/PRBTest.sol";

// Contracts
import {AnyReputationToken, PaymentToken} from "./Helpers/HelperTokens.sol";
import {ReputationEngineInterface} from "src/Modules/Reputation/interfaces/ReputationEngineInterface.sol";
import {ReputationEngine} from "src/Modules/Reputation/ReputationEngine.sol";

import {LaborMarketInterface} from "src/LaborMarket/interfaces/LaborMarketInterface.sol";
import {LaborMarket} from "src/LaborMarket/LaborMarket.sol";

import {LaborMarketFactory} from "src/Network/LaborMarketFactory.sol";
import {LaborMarketNetwork} from "src/Network/LaborMarketNetwork.sol";
import {LaborMarketVersions} from "src/Network/LaborMarketVersions.sol";

import {ReputationModule} from "src/Modules/Reputation/ReputationModule.sol";
import {ReputationModuleInterface} from "src/Modules/Reputation/interfaces/ReputationModuleInterface.sol";

import {LikertEnforcementCriteria} from "src/Modules/Enforcement/LikertEnforcementCriteria.sol";
import {FCFSEnforcementCriteria} from "src/Modules/Enforcement/FCFSEnforcementCriteria.sol";
import {Best5EnforcementCriteria} from "src/Modules/Enforcement/Best5EnforcementCriteria.sol";
import {MerkleEnforcementCriteria} from "src/Modules/Enforcement/MerkleEnforcementCriteria.sol";

import {PaymentModule} from "src/Modules/Payment/PaymentModule.sol";
import {PayCurve} from "src/Modules/Payment/PayCurve.sol";

import {LaborMarketConfigurationInterface} from "src/LaborMarket/interfaces/LaborMarketConfigurationInterface.sol";
import {LaborMarketNetworkInterface} from "src/Network/interfaces/LaborMarketNetworkInterface.sol";

contract ContractTest is PRBTest, StdCheats {
    AnyReputationToken public repToken;
    PaymentToken public payToken;

    LaborMarket public marketImplementation;
    LaborMarket public likertMarket;
    LaborMarket public fcfsMarket;
    LaborMarket public best5Market;
    LaborMarket public merkleMarket;

    ReputationEngine public reputationEngineMaster;
    ReputationEngine public reputationEngine;

    ReputationModule public reputationModule;

    LaborMarketFactory public factory;

    LaborMarketNetwork public network;

    LikertEnforcementCriteria public likertEnforcement;
    FCFSEnforcementCriteria public fcfsEnforcement;
    Best5EnforcementCriteria public best5Enforcement;
    MerkleEnforcementCriteria public merkleEnforcement;

    PaymentModule public paymentModule;
    PayCurve public payCurve;

    // Define the tokenIds for ERC1155
    uint256 private constant DELEGATE_TOKEN_ID = 0;
    uint256 private constant REPUTATION_TOKEN_ID = 1;
    uint256 private constant PAYMENT_TOKEN_ID = 2;
    uint256 private constant MAINTAINER_TOKEN_ID = 3;
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
    // Evil user
    address private delegate =
        address(uint160(uint256(keccak256("DELEGATOOOR"))));

    // Events
    event LaborMarketConfigured(
        LaborMarketConfigurationInterface.LaborMarketConfiguration indexed configuration
    );

    event RequestWithdrawn(uint256 indexed requestId);

    event LaborMarketCreated(
        address indexed marketAddress,
        address indexed owner,
        address indexed implementation
    );

    event RequestCreated(
        address indexed requester,
        uint256 indexed requestId,
        string indexed uri,
        address pToken,
        uint256 pTokenQ,
        uint256 signalExp,
        uint256 submissionExp,
        uint256 enforcementExp
    );

    event RequestSignal(
        address indexed signaler,
        uint256 indexed requestId,
        uint256 signalAmount
    );

    event ReviewSignal(
        address indexed signaler,
        uint256 indexed quantity,
        uint256 signalAmount
    );

    event RequestFulfilled(
        address indexed fulfiller,
        uint256 indexed requestId,
        uint256 indexed submissionId
    );

    event RequestReviewed(
        address reviewer,
        uint256 indexed requestId,
        uint256 indexed submissionId,
        uint256 indexed reviewScore
    );

    event RequestPayClaimed(
        address indexed claimer,
        uint256 indexed submissionId,
        uint256 indexed payAmount,
        address to
    );

    event RemainderClaimed(
        address indexed claimer,
        uint256 indexed requestId,
        uint256 remainderAmount
    );

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/
    function setUp() public {
        vm.startPrank(deployer);

        // Create a capacity & reputation token
        payToken = new PaymentToken(deployer);

        // Generic reputation token
        repToken = new AnyReputationToken("reputation nation", deployer);

        // Deploy an empty labor market for implementation
        marketImplementation = new LaborMarket();

        // Deploy reputation token implementation
        reputationEngineMaster = new ReputationEngine();

        // Deploy a labor market factory
        factory = new LaborMarketFactory(address(marketImplementation));

        // Deploy a labor market network
        network = new LaborMarketNetwork({
            _factoryImplementation: address(marketImplementation),
            _capacityImplementation: address(address(0))
        });

        // Deploy a new reputation module
        reputationModule = new ReputationModule(address(network));

        // Create enforcement criteria
        likertEnforcement = new LikertEnforcementCriteria();
        fcfsEnforcement = new FCFSEnforcementCriteria();
        best5Enforcement = new Best5EnforcementCriteria();
        merkleEnforcement = new MerkleEnforcementCriteria();

        // Create a payment module
        paymentModule = new PaymentModule();

        // Create a new pay curve
        payCurve = new PayCurve();

        // Create a reputation token
        reputationEngine = ReputationEngine(
            reputationModule.createReputationEngine(
                address(reputationEngineMaster),
                address(repToken),
                REPUTATION_TOKEN_ID,
                REPUTATION_DECAY_RATE,
                REPUTATION_DECAY_INTERVAL
            )
        );

        // Reputation config
        ReputationModuleInterface.ReputationMarketConfig
            memory repConfig = ReputationModuleInterface
                .ReputationMarketConfig({
                    reputationEngine: address(reputationEngine),
                    signalStake: 1e18,
                    submitMin: 1e18,
                    submitMax: 10000e18
                });

        // Create a new labor market configuration for likert
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory likertConfig = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(likertEnforcement),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new labor market configuration for fcfs
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory fcfsConfig = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(fcfsEnforcement),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new labor market configuration for best5
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory best5Config = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(best5Enforcement),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new labor market configuration for merkle
        LaborMarketConfigurationInterface.LaborMarketConfiguration
            memory merkleConfig = LaborMarketConfigurationInterface
                .LaborMarketConfiguration({
                    network: address(network),
                    enforcementModule: address(merkleEnforcement),
                    paymentModule: address(payCurve),
                    marketUri: "ipfs://000",
                    delegateBadge: address(repToken),
                    delegateTokenId: DELEGATE_TOKEN_ID,
                    maintainerBadge: address(repToken),
                    maintainerTokenId: MAINTAINER_TOKEN_ID,
                    reputationModule: address(reputationModule),
                    reputationConfig: repConfig
                });

        // Create a new likert labor market
        likertMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: likertConfig
            })
        );

        // Create a new fcfs labor market
        fcfsMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: fcfsConfig
            })
        );

        // Create a new best5 labor market
        best5Market = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: best5Config
            })
        );

        // Create a new merkle labor market
        merkleMarket = LaborMarket(
            network.createLaborMarket({
                _implementation: address(marketImplementation),
                _deployer: deployer,
                _configuration: merkleConfig
            })
        );

        // Approve and mint tokens
        repToken.freeMint(alice, REPUTATION_TOKEN_ID, 100e18);
        repToken.freeMint(alice, DELEGATE_TOKEN_ID, 1);

        changePrank(alice);
        repToken.setApprovalForAll(address(likertMarket), true);
        repToken.setApprovalForAll(address(fcfsMarket), true);
        repToken.setApprovalForAll(address(best5Market), true);
        repToken.setApprovalForAll(address(merkleMarket), true);

        changePrank(deployer);
        repToken.freeMint(bob, REPUTATION_TOKEN_ID, 1000e18);
        repToken.freeMint(bob, DELEGATE_TOKEN_ID, 1);
        payToken.freeMint(bob, 1_000_000e18);
        repToken.freeMint(bob, MAINTAINER_TOKEN_ID, 1);

        changePrank(bob);
        repToken.setApprovalForAll(address(likertMarket), true);
        repToken.setApprovalForAll(address(fcfsMarket), true);
        repToken.setApprovalForAll(address(best5Market), true);
        repToken.setApprovalForAll(address(merkleMarket), true);

        payToken.approve(address(likertMarket), 1_000e18);
        payToken.approve(address(fcfsMarket), 1_000e18);
        payToken.approve(address(best5Market), 1_000e18);
        payToken.approve(address(merkleMarket), 1_000e18);

        changePrank(deployer);
        repToken.freeMint(bobert, REPUTATION_TOKEN_ID, 1000e18);
        repToken.freeMint(bobert, MAINTAINER_TOKEN_ID, 1);

        changePrank(bobert);
        repToken.setApprovalForAll(address(likertMarket), true);
        repToken.setApprovalForAll(address(fcfsMarket), true);
        repToken.setApprovalForAll(address(best5Market), true);
        repToken.setApprovalForAll(address(merkleMarket), true);

        changePrank(deployer);
        repToken.freeMint(delegate, DELEGATE_TOKEN_ID, 1);

        vm.stopPrank();
    }

    function createSimpleRequest(LaborMarket simpleMarket)
        internal
        returns (uint256)
    {
        uint256 rid = simpleMarket.submitRequest({
            pToken: address(payToken),
            pTokenQ: 1000e18,
            signalExp: block.timestamp + 1 hours,
            submissionExp: block.timestamp + 1 days,
            enforcementExp: block.timestamp + 1 weeks,
            requestUri: "ipfs://222"
        });

        return rid;
    }

    function pseudoRandom(uint256 _n) internal view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, _n))
            ) / 1.5e75;
    }

    function coinflip() internal view returns (uint256) {
        return ((pseudoRandom(123) + uint160(msg.sender)) % 2) == 0 ? 1 : 0;
    }

    function test_LikertMarket() public {
        /**
        | Here we test the workings of enforcement (reviewing) following a likert metric.
        |
        | First, we populate the request with submissions
        | Second, we review the submissions
        | Third, we test the enforcement criteria following an example scenario.
        | 
        | * Example scenario:
        | pTokens: 1000
        | Participants: 112
        | Likert ratings: (1, BAD), (2, OK), (3, GOOD)
        | Bucket distribution: (1, 66), (2, 36), (3, 10)
        | Payout distribution: (1, 0), (2, 20%), (3, 80%)
        | Expected Tokens per person per bucket: (1, 0), (2, 5.5), (3, 80)
        */

        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(likertMarket);

        // Signal the request on 112 accounts
        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);
            changePrank(user);

            // Aprove the market
            repToken.setApprovalForAll(address(likertMarket), true);

            likertMarket.signal(requestId);
            likertMarket.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        likertMarket.signalReview(115);

        // The reviewer reviews the submissions
        for (uint256 i; i < 113; i++) {
            if (i < 67) {
                // BAD
                likertMarket.review(requestId, i + 1, 0);
            } else if (i < 103) {
                // OK
                likertMarket.review(requestId, i + 1, 1);
            } else {
                // GOOD
                likertMarket.review(requestId, i + 1, 2);
            }
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i; i < 113; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            totalPaid += likertMarket.claim(i + 1, msg.sender, "");
        }

        assertAlmostEq(totalPaid, 1000e18, 0.000001e18);
    }

    function test_Best5Market() public {
        /**
        | Here we test the workings of enforcement (reviewing) following a top 5 metric
        |
        | First, we populate the request with submissions
        | Second, we review the submissions
        | Third, we sort the submissions based on review ranking
        | 
        | * Example scenario:
        | pTokens: 1000
        | Participants: 55
        | Scores are randomly generated
        | 5 winners who each receive 200 tokens (scaling index of 20)
        | point on curve * base payout = payout
        */

        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(best5Market);

        // Signal the request on 55 accounts
        for (uint256 i; i < 55; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);
            changePrank(user);

            // Aprove the market
            repToken.setApprovalForAll(address(best5Market), true);

            best5Market.signal(requestId);
            best5Market.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        best5Market.signalReview(115);

        // The reviewer reviews the submissions
        for (uint256 i; i < 55; i++) {
            best5Market.review(requestId, i + 1, pseudoRandom(i));
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i; i < 55; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            totalPaid += best5Market.claim(i + 1, msg.sender, "");
        }

        best5Enforcement.getSubmissions(address(best5Market), requestId);
    }

    function test_FcfsMarket() public {
        /**
        | Here we test the workings of enforcement (reviewing) following a first come first serve metric
        |
        | First, we populate the request with submissions
        | Second, we review the submissions
        | Third, the first 10 submissions scored a 1 are paid out
        | 
        | * Example scenario:
        | pTokens: 1000
        | Participants: 75
        | Scores are randomly generated
        */

        vm.startPrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(fcfsMarket);

        // Signal the request on 75 accounts
        for (uint256 i; i < 75; i++) {
            address user = address(uint160(1337 + i));

            // Mint required tokens
            changePrank(deployer);
            repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
            repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);
            changePrank(user);

            // Aprove the market
            repToken.setApprovalForAll(address(fcfsMarket), true);

            fcfsMarket.signal(requestId);
            fcfsMarket.provide(requestId, "NaN");
        }

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        fcfsMarket.signalReview(115);

        // The reviewer reviews the submissions
        for (uint256 i; i < 75; i++) {
            fcfsMarket.review(requestId, i + 1, coinflip());
        }

        // Keeps track of the total amount paid out
        uint256 totalPaid;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        for (uint256 i; i < 55; i++) {
            address user = address(uint160(1337 + i));
            changePrank(user);

            // Claim
            totalPaid += fcfsMarket.claim(i + 1, msg.sender, "");
        }
    }

    function test_LikertClaimRemainder() public {
        vm.startPrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(likertMarket);

        // A valid user signals
        changePrank(alice);
        likertMarket.signal(requestId);

        // User fulfills the request
        uint256 submissionId = likertMarket.provide(requestId, "IPFS://333");

        // A valid maintainer signals for review
        changePrank(bobert);
        likertMarket.signalReview(3);

        // A valid maintainer reviews the request and scores it a 1
        likertMarket.review(requestId, submissionId, 1);

        // Skip past enforcement deadline
        vm.warp(block.timestamp + 100 weeks);

        // Requester withdraws remainder
        // Score should average to 1 meaning it falls in the 20% bucket, the remainder should therefore be 80% of the reward
        changePrank(bob);

        vm.expectEmit(true, true, true, true);
        emit RemainderClaimed(address(bob), requestId, 800e18);
        likertMarket.claimRemainder(requestId);
    }

    function test_Best5ClaimRemainder() public {
        vm.startPrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(best5Market);

        // A valid user signals
        changePrank(alice);
        best5Market.signal(requestId);

        // User fulfills the request
        uint256 submissionId = best5Market.provide(requestId, "IPFS://333");

        // A valid maintainer signals for review
        changePrank(bobert);
        best5Market.signalReview(3);

        // A valid maintainer reviews the request and scores it a 1
        best5Market.review(requestId, submissionId, 1);

        // Skip past enforcement deadline
        vm.warp(block.timestamp + 100 weeks);

        // Requester withdraws remainder
        // The remainder should be indexes 2, 3, 4 and 5.
        changePrank(bob);

        vm.expectEmit(true, true, true, true);
        emit RemainderClaimed(address(bob), requestId, 21600);
        best5Market.claimRemainder(requestId);
    }

    function test_FcfsClaimRemainder() public {
        vm.startPrank(bob);
        // Create a request
        uint256 requestId = createSimpleRequest(fcfsMarket);

        // A valid user signals
        changePrank(alice);
        fcfsMarket.signal(requestId);

        // User fulfills the request
        uint256 submissionId = fcfsMarket.provide(requestId, "IPFS://333");

        // A valid maintainer signals for review
        changePrank(bobert);
        fcfsMarket.signalReview(3);

        // A valid maintainer reviews the request and scores it a 1
        fcfsMarket.review(requestId, submissionId, 1);

        // Skip past enforcement deadline
        vm.warp(block.timestamp + 100 weeks);

        // Requester withdraws remainder
        // The remainder should be indexes 2...9.
        changePrank(bob);

        vm.expectEmit(true, true, true, true);
        emit RemainderClaimed(address(bob), requestId, 285);
        fcfsMarket.claimRemainder(requestId);
    }

    function test_MerkleMarket() public {
        /**
        | Here we test the workings of enforcement (reviewing), where submissions are required to be in a given merkle tree
        |
        | First, we populate the tree with submissions,market pairs: [[1, 0xc0425dBe34a7C865A90e8B3d9535Fa8b26e1ef8f], [2, 0xc0425dBe34a7C865A90e8B3d9535Fa8b26e1ef8f], [3, 0xc0425dBe34a7C865A90e8B3d9535Fa8b26e1ef8f], [4, 0xc0425dBe34a7C865A90e8B3d9535Fa8b26e1ef8f], [5, 0xc0425dBe34a7C865A90e8B3d9535Fa8b26e1ef8f]]; which gives us:
        Root: 0xe53a420a8be832d2d6d50aa7f5d9805ffe3ec89795af36bf2c738b719b52fae3
        0) e53a420a8be832d2d6d50aa7f5d9805ffe3ec89795af36bf2c738b719b52fae3
        ├─ 1) 04a603ce59d42ef7bb52d5cfeeac775d6478333a176a39ea3dbeed971bca82b3
        │  ├─ 3) f45555fa491944479ca61cd307da5181f83f3fe03b20244c693065658de9573b
        │  │  ├─ 7) 52745c64e39ba07f218a832f27edf3845f50b3b7502ac4f9e881c0461b8ff37f
        │  │  └─ 8) 0433f2ddce883004c48489ffade0a993100ab19aa4a9b064b78dc4f477275573
        │  └─ 4) d193f622940a2b677aea02cd195c5a692eca67b29fa54b93f1e0a03bb48d8a6a
        └─ 2) 3bbe8d68e7fb3c3f69bc13e345b5d3df35bff882dc09169b24a4c946456551cc
        ├─ 5) 916845823bd997f675d71546551d80e5c9f7c69ea8efc5ab4fe955c6cf25ab1b
        └─ 6) 8c35c85082c0770ca640e6a83f8ec917fcfaebdee709a5eb98e1aeac5ed0a921
        | 
        | Second, we review the submissions
        | Third, we claim the reward with a valid proof
        */

        vm.startPrank(deployer);
        merkleEnforcement.setRoot(
            1,
            0xe53a420a8be832d2d6d50aa7f5d9805ffe3ec89795af36bf2c738b719b52fae3
        );

        changePrank(bob);

        // Create a request
        uint256 requestId = createSimpleRequest(merkleMarket);

        // Signal the request on an account
        address user = address(uint160(1337));

        // Mint required tokens
        changePrank(deployer);
        repToken.freeMint(user, DELEGATE_TOKEN_ID, 1);
        repToken.freeMint(user, REPUTATION_TOKEN_ID, 100e18);
        changePrank(user);

        // Aprove the market
        repToken.setApprovalForAll(address(merkleMarket), true);

        merkleMarket.signal(requestId);
        merkleMarket.provide(requestId, "NaN");

        // Have bob review the submissions
        changePrank(bob);

        // The reviewer signals the requestId
        merkleMarket.signalReview(115);

        // The reviewer reviews the submissions
        merkleMarket.review(requestId, 1, 5);

        // Keeps track of the total amount paid out
        uint256 totalPaid;

        // Skip to enforcement deadline
        vm.warp(5 weeks);

        // Claim rewards
        changePrank(user);

        bytes memory invalidProof = bytes.concat(
            bytes32(
                0x00000000000000000000000000000000000000000000000000000000000000Ee
            ),
            bytes32(
                0x00000000000000000000000000000000000000000000000000000000000000aA
            )
        );

        bytes memory proof = bytes.concat(
            bytes32(
                0x52745c64e39ba07f218a832f27edf3845f50b3b7502ac4f9e881c0461b8ff37f
            ),
            bytes32(
                0xd193f622940a2b677aea02cd195c5a692eca67b29fa54b93f1e0a03bb48d8a6a
            ),
            bytes32(
                0x3bbe8d68e7fb3c3f69bc13e345b5d3df35bff882dc09169b24a4c946456551cc
            )
        );

        // Another user cannot claim with others proof
        changePrank(alice);
        vm.expectRevert("LaborMarket::claim: Not service provider.");
        merkleMarket.claim(1, msg.sender, proof);

        // Claim with invalid proof should fail
        changePrank(user);
        vm.expectRevert("EnforcementCriteria::verifyWithData: invalid proof");
        totalPaid += merkleMarket.claim(1, msg.sender, invalidProof);

        // Successful Claim
        totalPaid += merkleMarket.claim(1, msg.sender, proof);

        // Claiming again should fail
        vm.expectRevert("LaborMarket::claim: Already claimed.");
        merkleMarket.claim(1, msg.sender, proof);
    }
}
