const hre = require('hardhat');
const { assert, expect } = require('chai');
const { loadFixture, mine } = require('@nomicfoundation/hardhat-network-helpers');

require('chai').use(require('chai-as-promised')).should();

const ethers = hre.ethers;

import type { LaborMarketInterface } from '../package/types/src/LaborMarket';

async function getCurrentBlockTimestamp() {
    return hre.ethers.provider.getBlock('latest').then((block: any) => block.timestamp);
}

describe('Labor Market', function () {
    async function getSigners() {
        const [deployer, reviewer, provider1, provider2, badActor] = await ethers.getSigners();
        return { deployer, reviewer, provider1, provider2, badActor };
    }

    async function deployLaborMarketSingleton() {
        const LaborMarket = await ethers.getContractFactory('LaborMarket');
        const laborMarketSingleton = await LaborMarket.deploy();
        await laborMarketSingleton.deployed();

        return { laborMarketSingleton };
    }

    async function deployFactory() {
        const { laborMarketSingleton } = await loadFixture(deployLaborMarketSingleton);

        const Factory = await ethers.getContractFactory('LaborMarketFactory');
        const factory = await Factory.deploy(laborMarketSingleton.address);
        await factory.deployed();

        const EnforcementCriteria = await ethers.getContractFactory('ScalableLikertEnforcement');
        const enforcement = await EnforcementCriteria.deploy();
        await enforcement.deployed();

        return { laborMarketSingleton, factory, enforcement };
    }

    async function deployCoins() {
        const { deployer } = await loadFixture(getSigners);

        const ERC20 = await ethers.getContractFactory('ERC20FreeMint');

        const [PEPE, wETH, NEAR, USDC] = await Promise.all([
            ERC20.deploy('PEPE', 'PEPE', 18),
            ERC20.deploy('ETH', 'ETH', 18),
            ERC20.deploy('NEAR', 'NEAR', 18),
            ERC20.deploy('USDC', 'USDC', 6),
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

    async function createMarket(
        auxilaries: number[] = [4],
        alphas: number[] = [0, 1, 2, 3, 4],
        betas: number[] = [0, 0, 100, 200, 300],
    ) {
        const { factory, enforcement, laborMarketSingleton } = await loadFixture(deployFactory);
        const signers = await loadFixture(getSigners);

        const sigs: any = [];

        const nodes: any = [];

        const args = [
            signers.deployer.address, // address _deployer,
            enforcement.address, // EnforcementCriteriaInterface _criteria,
            auxilaries, // uint256[] memory _auxilaries,
            alphas, // uint256[] memory _alphas,
            betas, // uint256[] memory _betas
            sigs, // bytes4[] memory _sigs,
            nodes, // Node[] memory _nodes,
        ];

        const marketAddress = await factory.callStatic.createLaborMarket(...args);

        console.log('marketAddress', marketAddress);

        await expect(factory.createLaborMarket(...args))
            .to.emit(factory, 'LaborMarketCreated')
            .withArgs(marketAddress, signers.deployer.address, laborMarketSingleton.address);

        const market = await ethers.getContractAt('LaborMarket', marketAddress);

        return { market, factory, enforcement, ...signers };
    }

    async function createMarketWithRequest() {
        const { market, deployer } = await loadFixture(createMarket);
        const { pepe, usdc } = await loadFixture(deployCoins);
        const signers = await loadFixture(getSigners);

        const now = await getCurrentBlockTimestamp();

        await (await pepe.approve(market.address, ethers.utils.parseEther('1000000'))).wait();
        await (await usdc.approve(market.address, ethers.utils.parseEther('1000000'))).wait();

        const request: LaborMarketInterface.ServiceRequestStruct = {
            signalExp: now + 1000, // uint48
            submissionExp: now + 2000, // uint48
            enforcementExp: now + 3000, // uint48
            providerLimit: 100, // uint64
            reviewerLimit: 100, // uint64
            pTokenProviderTotal: 100, // uint256
            pTokenReviewerTotal: 100, // uint256
            pTokenProvider: pepe.address, // IERC20
            pTokenReviewer: usdc.address, // IERC20
        };

        console.log('request', request);

        const requestId = await market.connect(deployer).callStatic.submitRequest(0, request, 'insertURIhere');

        // const requestId = 0;

        // const tx = await market.connect(deployer).submitRequest(0, request, 'insertURIhere');
        // const receipt = await tx.wait();
        // console.log(receipt);
        // expect(await market.submitRequest(0, request, 'insertURIhere')).to.emit(market, 'RequestConfigured');

        return { market, requestId, ...signers };
    }

    describe('LaborMarketFactory.sol', async () => {
        it('call: createMarket()', async () => {
            const { factory, enforcement, laborMarketSingleton } = await loadFixture(deployFactory);
            const { deployer } = await loadFixture(getSigners);

            const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
            const auxilaries = [4];
            const alphas = [0, 1, 2, 3, 4];
            const betas = [0, 0, 100, 200, 300];
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

            const contractAddress = await factory.callStatic.createLaborMarket(...args);

            await expect(factory.createLaborMarket(...args))
                .to.emit(factory, 'LaborMarketCreated')
                .withArgs(contractAddress, deployer.address, laborMarketSingleton.address);
        });
    });

    describe('LaborMarket.sol', async () => {
        it('call: submitRequest()', async () => {
            const { market } = await loadFixture(createMarket);
            const { pepe, usdc } = await loadFixture(deployCoins);
            const now = await getCurrentBlockTimestamp();
            const request: LaborMarketInterface.ServiceRequestStruct = {
                signalExp: now + 1000, // uint48
                submissionExp: now + 2000, // uint48
                enforcementExp: now + 3000, // uint48
                providerLimit: 100, // uint64
                reviewerLimit: 100, // uint64
                pTokenProviderTotal: 100, // uint256
                pTokenReviewerTotal: 100, // uint256
                pTokenProvider: pepe.address, // IERC20
                pTokenReviewer: usdc.address, // IERC20
            };
            expect(await market.submitRequest(0, request, 'insertURIhere')).to.emit(market, 'RequestConfigured');
        });
        it('call: signal()', async () => {
            const { market, requestId, provider1 } = await loadFixture(createMarketWithRequest);

            console.log('requestId', requestId);

            await expect(market.signal(0)).to.emit(market, 'RequestSignal').withArgs(provider1.address, 0);

            await expect(market.requestIdToRequest(0).then((r: any) => r.providerTotal)).to.equal(
                ethers.utils.parseEther('1000000'),
            );
        });
        it('call: signalReview()', async () => {});
        it('call: provide()', async () => {});
        it('call: review()', async () => {});
        it('call: claim()', async () => {});
        it('call: claimRemainder()', async () => {});
        it('call: withdrawRequest()', async () => {});
    });
});
