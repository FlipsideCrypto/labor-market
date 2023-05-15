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

    const LaborMarketImplementation = '0xc8f98075fcfA38024069Be0b2202d25bA22C682c';
    const LaborMarketFactory = '0x95be852eCa7d66A406e283b1d79DB268Dff698a0';
    const EnforcementCriteria = '0x7207dDC1A67d18A953e97E373617F338efe1677E';

    const verifications = await Promise.all([
        hre.run('verify:verify', { address: LaborMarketImplementation, constructorArguments: [] }),
        hre.run('verify:verify', { address: LaborMarketFactory, constructorArguments: [LaborMarketImplementation] }),
        hre.run('verify:verify', { address: EnforcementCriteria, constructorArguments: [] }),
    ]);

    console.log(verifications);
    console.log('Protocol Deployed and Verified!');
}

main();
