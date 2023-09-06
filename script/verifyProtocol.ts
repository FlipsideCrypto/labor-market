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

    const LaborMarketImplementation = '0xF89a26006AbB9a72b2b41abAE575821eD02aC134';
    const LaborMarketFactory = '0x1D9285FeF4a58256A2A58A1a66AC7739Ee9dAA3A';
    const EnforcementCriteria = '0xc104a1884e9788db6426c56F44daA5121c72A97E';

    await hre.run('verify:verify', { address: LaborMarketImplementation, constructorArguments: [] });

    await hre.run('verify:verify', { address: LaborMarketFactory, constructorArguments: [LaborMarketImplementation] });

    await hre.run('verify:verify', { address: EnforcementCriteria, constructorArguments: [] });
}

main();
