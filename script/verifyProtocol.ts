const hre = require('hardhat');
const { expect } = require('chai');
const { ethers } = require('hardhat');

async function main() {
    const [deployer] = await ethers.getSigners();
    const balance = ethers.utils.formatEther(await deployer.getBalance());
    const chainId = hre.network.config.chainId;

    console.table({
        'Deployer': deployer.address,
        'Chain ID': chainId,
        'Balance': balance,
    });

    const LaborMarketImplementation = '0x6C257AeEdeF026c4e25fB1b8DC0CfB78c0495629';
    const LaborMarketFactory = '0x04E76d1FC8653c3914cEAb2D013D6D2a82858732';
    const EnforcementCriteria = '0x7207dDC1A67d18A953e97E373617F338efe1677E';

    hre.run('verify:verify', { address: LaborMarketImplementation, constructorArguments: [] });
    console.log('Implementation Verified');

    hre.run('verify:verify', { address: LaborMarketFactory, constructorArguments: [LaborMarketImplementation] });
    console.log('Factory Verified');

    hre.run('verify:verify', { address: EnforcementCriteria, constructorArguments: [] });
    console.log('Enforcement Verified');
}

main();
