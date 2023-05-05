const hre = require('hardhat');
const { assert, expect } = require('chai');
const { loadFixture, mine } = require('@nomicfoundation/hardhat-network-helpers');

require('chai').use(require('chai-as-promised')).should();

const ethers = hre.ethers;

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

        return { factory, enforcement };
    }

    async function createMarket(auxilaries: number[], alphas: number[], betas: number[]) {
        const { factory, enforcement } = await loadFixture(deployFactory);
        const { deployer } = await loadFixture(getSigners);

        const _criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,

        const marketAddress = await factory.createLaborMarket(deployer.address, _criteria, auxilaries, alphas, betas);
        const market = await ethers.getContractAt('LaborMarket', marketAddress);

        return { market, enforcement };
    }

    describe('LaborMarket.sol', async () => {
        it('call: createMarket()', async () => {
            const { factory, enforcement } = await loadFixture(deployFactory);
            const { deployer } = await loadFixture(getSigners);

            const _criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
            const auxilaries = [4];
            const alphas = [0, 1, 2, 3, 4];
            const betas = [0, 0, 100, 200, 300];

            await expect(factory.createLaborMarket(deployer.address, _criteria, auxilaries, alphas, betas)).to.emit(
                factory,
                'LaborMarketCreated',
            );
        });
    });
});
