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

    async function createMarket(auxilaries: number[] = [1], alphas: number[] = [0, 1], betas: number[] = [0, 1]) {
        const { factory, enforcement, ERC20s } = await loadFixture(deployFactory);
        const [deployer] = await ethers.getSigners();

        const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
        const sigs: any = [];
        const nodes: any = [];

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

    describe('Pass Fail Enforcement', async () => {
        it('Pass Fail', async () => {
            const { market, ERC20s } = await loadFixture(createMarket);

            // Create a pass fail request
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

            const tx = await market.submitRequest(0, request, 'uri');
            const receipt = await tx.wait();

            const requestId = receipt.events.find((e: any) => e.event === 'RequestConfigured').args.requestId;
        });
    });
});
