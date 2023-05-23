const hre = require('hardhat');
const { expect } = require('chai');
const { ethers } = require('hardhat');

async function main(verify) {
    const [deployer] = await ethers.getSigners();
    const balance = ethers.utils.formatEther(await deployer.getBalance());
    const chainId = hre.network.config.chainId;

    console.table({
        'Deployer': deployer.address,
        'Chain ID': chainId,
        'Balance': balance,
    });

    const market = await ethers
        .getContractFactory('LaborMarket')
        .then((contract) => contract.deploy())
        .then((contract) => contract.deployed())
        .finally(() => {
            console.log('Implementation Deployed');
        });

    const factory = await ethers
        .getContractFactory('LaborMarketFactory')
        .then((contract) => contract.deploy(market.address))
        .then((contract) => contract.deployed())
        .finally(() => {
            console.log('Factory Deployed');
        });

    const enforcement = await ethers
        .getContractFactory('BucketEnforcement')
        .then((contract) => contract.deploy())
        .then((contract) => contract.deployed())
        .finally(() => {
            console.log('Enforcement Deployed');
        });

    console.table({
        'Labor Market Implementation': market.address,
        'Labor Market Factory': factory.address,
        'Enforcement Criteria': enforcement.address,
    });

    if (verify === true) {
        await new Promise((r) => setTimeout(r, 60000));

        hre.run('verify:verify', { address: market.address, constructorArguments: [] });
        console.log('Implementation Verified');

        hre.run('verify:verify', { address: factory.address, constructorArguments: [market.address] });
        console.log('Factory Verified');

        hre.run('verify:verify', { address: enforcement.address, constructorArguments: [] });
        console.log('Enforcement Verified');
    }
}

main(true);
