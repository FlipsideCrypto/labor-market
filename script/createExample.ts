const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

import { LaborMarketConfigurationInterface } from "../package/dist/types/src/LaborMarket/LaborMarket";
import { LaborMarket, LaborMarketNetwork, ReputationModule, ConstantLikertEnforcement, PaymentModule, ReputationToken } from "../package/dist";

async function create() {
    const [deployer] = await ethers.getSigners();
    const balance = ethers.utils.formatEther(await deployer.getBalance());
    const chainId = hre.network.config.chainId;

    console.table({
        deployer: deployer.address,
        balance: balance,
        chainId: chainId
    })

    const network = new ethers.Contract(
        LaborMarketNetwork.address,
        LaborMarketNetwork.abi,
        deployer
    )

    const modules: LaborMarketConfigurationInterface.ModulesStruct = {
        reputation: ReputationModule.address,
        enforcement: ConstantLikertEnforcement.address,
        payment: PaymentModule.address,
        network: LaborMarketNetwork.address
    }

    const delegate: LaborMarketConfigurationInterface.BadgePairStruct = {
        token: ReputationToken.address,
        tokenId: 2
    }

    const maintainer: LaborMarketConfigurationInterface.BadgePairStruct = {
        token: ReputationToken.address,
        tokenId: 3
    }

    const reputation: LaborMarketConfigurationInterface.BadgePairStruct = {
        token: ReputationToken.address,
        tokenId: 4
    }

    const reputationParams: LaborMarketConfigurationInterface.ReputationParamsStruct = {
        rewardPool: 5000,
        signalStake: 5,
        submitMin: 0,
        submitMax: 10000000,
    }

    const args: LaborMarketConfigurationInterface.LaborMarketConfigurationStruct = {
        marketUri: "ipfs/uri",
        owner: deployer.address,
        modules: modules,
        delegateBadge: delegate,
        maintainerBadge: maintainer,
        reputationBadge: reputation,
        reputationParams: reputationParams
    }

    const tx = await network.createLaborMarket(
        LaborMarket.address,
        args
    );
    const receipt = await tx.wait();
    console.log('Receipt: ', receipt.events[3].args[0]);

    // const market = ethers.utils.getContractAt("LaborMarket", receipt.events[3].args[0]);

    // const tx2 = await market.submitRequest(
    //     "ipfs/uri",

    // )
}

create();