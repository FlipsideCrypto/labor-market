const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

import abi from "../../package/abis/BadgerOrganization.json" assert { type: 'json'}

const addresses = [
    "0x"
]

const tokenId = 4;

const amounts = Array(addresses.length).fill(100000);


async function distributeBadges() {
    const [deployer] = await ethers.getSigners();
    const provider = new ethers.providers.JsonRpcProvider(process.env.POLYGON_RPC_URL);

    const badgerAddress = "0x854DE1bf96dFBe69FC46f1a888d26934Ad47B77f";

    const cleanedAddresses = addresses.map((address) => {
        return ethers.utils.getAddress(address);
    });

    const badger = await new ethers.Contract(
        badgerAddress, 
        abi,
        provider
    );
    
    const tx = await badger.connect(deployer).leaderMintBatch(
        cleanedAddresses,
        tokenId,
        amounts,
        "0x"
    );

    const receipt = await tx.wait();

    console.log("Transaction receipt: ", receipt);
}

distributeBadges();