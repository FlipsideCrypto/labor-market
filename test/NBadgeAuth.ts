const hre = require('hardhat');
const { assert, expect } = require('chai');
const { loadFixture, mine } = require('@nomicfoundation/hardhat-network-helpers');

require('chai').use(require('chai-as-promised')).should();

const ethers = hre.ethers;

import type { LaborMarketInterface } from '../package/types/src/LaborMarket';
import type { NBadgeAuthInterface } from '../package/types/src/auth/NBadgeAuth';

async function getCurrentBlockTimestamp() {
    return hre.ethers.provider.getBlock('latest').then((block: any) => block.timestamp);
}

describe('Labor Market', function () {
    async function deployTokens() {
        const [deployer] = await ethers.getSigners();

        const ERC20 = await ethers.getContractFactory('ERC20FreeMint');

        const [PEPE, wETH, NEAR, USDC] = await Promise.all([
            ERC20.deploy('PEPE', 'PEPE', 18),
            ERC20.deploy('ETH', 'ETH', 18),
            ERC20.deploy('NEAR', 'NEAR', 18),
            ERC20.deploy('USDC', 'USDC', 18),
        ]);

        const [pepe, weth, near, usdc] = await Promise.all([
            PEPE.deployed(),
            wETH.deployed(),
            NEAR.deployed(),
            USDC.deployed(),
        ]);

        const [pepeMint, wethMint, nearMint, usdcMint] = await Promise.all([
            pepe.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
            weth.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
            near.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
            usdc.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
        ]);

        const ERC1155 = await ethers.getContractFactory('ERC1155FreeMint');
        const [Pine, Samurai, EagerBeavers] = await Promise.all([ERC1155.deploy(), ERC1155.deploy(), ERC1155.deploy()]);

        const [pine, samurai, beavers] = await Promise.all([
            Pine.deployed(),
            Samurai.deployed(),
            EagerBeavers.deployed(),
        ]);

        const [pineMint, samuraiMint, beaversMint] = await Promise.all([
            pine.freeMint(deployer.address, 1, 10),
            samurai.freeMint(deployer.address, 1, 10),
            beavers.freeMint(deployer.address, 1, 10),
        ]);

        await Promise.all([
            pepeMint.wait(),
            wethMint.wait(),
            nearMint.wait(),
            usdcMint.wait(),
            pineMint.wait(),
            samuraiMint.wait(),
            beaversMint.wait(),
        ]);

        return {
            ERC20s: { pepe, weth, near, usdc },
            badges: [pine, samurai, beavers],
        };
    }

    async function deployLaborMarketSingleton() {
        const { ERC20s, Badges } = await loadFixture(deployTokens);

        const LaborMarket = await ethers.getContractFactory('LaborMarket');
        const laborMarketSingleton = await LaborMarket.deploy();
        await laborMarketSingleton.deployed();

        return { laborMarketSingleton, ERC20s };
    }

    async function deployFactory() {
        const { laborMarketSingleton, ERC20s } = await loadFixture(deployLaborMarketSingleton);

        const Factory = await ethers.getContractFactory('LaborMarketFactory');
        const factory = await Factory.deploy(laborMarketSingleton.address);
        await factory.deployed();

        const EnforcementCriteria = await ethers.getContractFactory('BucketEnforcement');
        const enforcement = await EnforcementCriteria.deploy();
        await enforcement.deployed();

        return { factory, enforcement, laborMarketSingleton, ERC20s };
    }

    async function createMarket() {
        const { factory, enforcement, ERC20s } = await loadFixture(deployFactory);
        const [deployer] = await ethers.getSigners();

        const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
        const sigs: any = [];
        const nodes: any = [];

        const maxScore = [100];
        const scoreRanges = [0, 25, 50, 70, 90];
        const scoreWeights = [0, 25, 50, 75, 100];

        const args = [
            deployer.address, // address _deployer,
            criteria, // EnforcementCriteriaInterface _criteria,
            maxScore, // uint256[] memory _auxilaries,
            scoreRanges, // uint256[] memory _alphas,
            scoreWeights, // uint256[] memory _betas
            sigs, // bytes4[] memory _sigs,
            nodes, // Node[] memory _nodes,
        ];

        const tx = await factory.createLaborMarket(...args);
        const receipt = await tx.wait();

        const event = receipt.events.find((e: any) => e.event === 'LaborMarketCreated');

        const marketAddress = event.args.marketAddress;

        const market = await ethers.getContractAt('LaborMarket', marketAddress);

        const [pepeApproval, usdcApproval, wethApproval, nearApproval] = await Promise.all([
            ERC20s.pepe.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
            ERC20s.usdc.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
            ERC20s.weth.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
            ERC20s.near.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
        ]);

        await Promise.all([pepeApproval.wait(), usdcApproval.wait(), wethApproval.wait(), nearApproval.wait()]);

        return { market, factory, enforcement, deployer, ERC20s };
    }

    async function createMarketWithRequest() {
        const { market, deployer, ERC20s } = await loadFixture(createMarket);

        const now = await getCurrentBlockTimestamp();

        const request: LaborMarketInterface.ServiceRequestStruct = {
            signalExp: now + 1000, // uint48
            submissionExp: now + 2000, // uint48
            enforcementExp: now + 3000, // uint48
            providerLimit: 100, // uint64
            reviewerLimit: 100, // uint64
            pTokenProviderTotal: ethers.utils.parseEther('100'), // uint256
            pTokenReviewerTotal: ethers.utils.parseEther('100'), // uint256
            pTokenProvider: ERC20s.pepe.address, // IERC20
            pTokenReviewer: ERC20s.usdc.address, // IERC20
        };

        const tx = await market.submitRequest(0, request, 'insertURIhere');
        const receipt = await tx.wait();

        const requestId = receipt.events.find((e: any) => e.event === 'RequestConfigured').args.requestId;

        return { market, requestId, ERC20s, deployer };
    }

    async function createMarketWithSubmission() {
        let { market, requestId, ERC20s } = await loadFixture(createMarketWithRequest);

        const [, provider] = await ethers.getSigners();

        market = market.connect(provider);

        const signal = await market.signal(requestId);
        await signal.wait();

        const submissionId = await market.callStatic.provide(requestId, 'uri');

        const provide = await market.provide(requestId, 'uri');
        await provide.wait();

        return { market, requestId, submissionId, ERC20s };
    }

    describe('NBadgeAuth', async () => {
        // it('call: createLaborMarket()', async () => {
        //     const { factory, enforcement, laborMarketSingleton } = await loadFixture(deployFactory);
        //     const [deployer] = await ethers.getSigners();
        //     const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
        //     const auxilaries = [4];
        //     const alphas = [0, 25, 50, 75, 90];
        //     const betas = [0, 25, 50, 75, 100];
        //     const sigs: any = [];
        //     const nodes: NBadgeAuthInterface.NodeStruct[] = [{}];
        //     const args = [
        //         deployer.address, // address _deployer,
        //         criteria, // EnforcementCriteriaInterface _criteria,
        //         auxilaries, // uint256[] memory _auxilaries,
        //         alphas, // uint256[] memory _alphas,
        //         betas, // uint256[] memory _betas
        //         sigs, // bytes4[] memory _sigs,
        //         nodes, // Node[] memory _nodes,
        //     ];
        //     const contractAddress = await factory.callStatic.createLaborMarket(...args);
        //     await expect(factory.createLaborMarket(...args))
        //         .to.emit(factory, 'LaborMarketCreated')
        //         .withArgs(contractAddress, deployer.address, laborMarketSingleton.address);
        // });
    });
});
