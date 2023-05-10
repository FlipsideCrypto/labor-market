const hre = require('hardhat');
const { assert, expect } = require('chai');
const { loadFixture, mine } = require('@nomicfoundation/hardhat-network-helpers');

require('chai').use(require('chai-as-promised')).should();

const ethers = hre.ethers;

import type { LaborMarketInterface } from '../package/types/src/LaborMarket';

async function getCurrentBlockTimestamp() {
    return hre.ethers.provider.getBlock('latest').then((block: any) => block.timestamp);
}

describe('Enforcement', function () {
    async function deployCoins() {
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

        await Promise.all([pepeMint.wait(), wethMint.wait(), nearMint.wait(), usdcMint.wait()]);

        return { pepe, weth, near, usdc };
    }

    async function deployLaborMarketSingleton() {
        const ERC20s = await loadFixture(deployCoins);

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

        const EnforcementCriteria = await ethers.getContractFactory('ScalableEnforcement');
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

        const auxilaries = [4];
        const alphas = [0, 1, 2, 3, 4];
        const betas = [0, 0, 100, 200, 300];

        const args = [
            deployer.address, // address _deployer,
            criteria, // EnforcementCriteriaInterface _criteria,
            auxilaries, // uint256[] memory _auxilaries,
            alphas, // uint256[] memory _alphas,
            betas, // uint256[] memory _betas
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

    describe('LaborMarketFactory.sol', async () => {});
});
