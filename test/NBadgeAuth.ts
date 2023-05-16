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
        const { factory, enforcement, ERC20s, laborMarketSingleton } = await loadFixture(deployFactory);
        const [deployer] = await ethers.getSigners();

        const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,

        const auxilaries = [100];
        const alphas = [0, 25, 50, 75, 90];
        const betas = [0, 25, 50, 75, 100];

        const ERC1155 = await ethers.getContractFactory('ERC1155FreeMint');
        let ERC1155s = await Promise.all(
            Array(10)
                .fill(0)
                .map(() => ERC1155.deploy()),
        );
        ERC1155s = await Promise.all(ERC1155s.map((e) => e.deployed()));

        const sigs: any = [laborMarketSingleton.interface.getSighash('signal(uint256)')];

        const badges: NBadgeAuthInterface.BadgeStruct[] = [
            {
                badge: ERC1155s[0].address,
                id: 0,
                min: 1,
                max: 1,
                points: 2,
            },
        ];

        const nodes: NBadgeAuthInterface.NodeStruct[] = [
            {
                deployerAllowed: true,
                badges: badges,
                required: 1,
            },
        ];

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

        return { market, factory, enforcement, deployer, ERC20s, ERC1155s };
    }

    describe('NBadgeAuth', async () => {
        it('call: createLaborMarket()', async () => {
            const { market, factory, enforcement, laborMarketSingleton, ERC20s, ERC1155s } = await loadFixture(
                createMarket,
            );

            const requester = await ethers.getSigner(1);
            const phony = await ethers.getSigner(2);

            const badge = ERC1155s[0];

            const badgeMint = await badge.freeMint(requester.address, 1, 1);
            await badgeMint.wait();

            const now = await getCurrentBlockTimestamp();

            const erc20Mints = await Promise.all([
                ERC20s.pepe.connect(requester).freeMint(requester.address, ethers.utils.parseEther('100000')),
                ERC20s.usdc.connect(requester).freeMint(requester.address, ethers.utils.parseEther('100000')),
                ERC20s.usdc.connect(phony).freeMint(phony.address, ethers.utils.parseEther('100000')),
                ERC20s.pepe.connect(phony).freeMint(phony.address, ethers.utils.parseEther('100000')),
            ]);
            await Promise.all(erc20Mints.map((e) => e.wait()));

            const approvals = await Promise.all([
                ERC20s.pepe.connect(requester).approve(market.address, ethers.utils.parseEther('100000')),
                ERC20s.usdc.connect(requester).approve(market.address, ethers.utils.parseEther('100000')),
                ERC20s.usdc.connect(phony).approve(market.address, ethers.utils.parseEther('100000')),
                ERC20s.pepe.connect(phony).approve(market.address, ethers.utils.parseEther('100000')),
            ]);
            await Promise.all(approvals.map((e) => e.wait()));

            // Configure the request
            const request: LaborMarketInterface.ServiceRequestStruct = {
                signalExp: now + 1000, // uint48
                submissionExp: now + 2000, // uint48
                enforcementExp: now + 3000, // uint48
                providerLimit: 5, // uint64
                reviewerLimit: 5, // uint64
                pTokenProviderTotal: ethers.utils.parseEther('100000'), // uint256
                pTokenReviewerTotal: ethers.utils.parseEther('1000'), // uint256
                pTokenProvider: ERC20s.pepe.address, // IERC20
                pTokenReviewer: ERC20s.usdc.address, // IERC20
            };

            const requestId = await market.connect(requester).callStatic.submitRequest(0, request, 'uri');

            expect(await market.connect(requester).submitRequest(0, request, 'uri')).to.emit(
                'RequestConfigured',
                requester.address,
                requestId,
            );

            expect(await market.connect(phony).submitRequest(0, request, 'uri')).to.be.revertedWith(
                'NBadgeAuth::requiresAuth: Not authorized',
            );
        });
    });
});
