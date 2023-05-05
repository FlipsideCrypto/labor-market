const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

async function verify() {
  /// LaborMarket: 0x14A2Eb1fC0275455B121c483Cc8818B5F659e916
  /// LaborMarketNetwork: 0xd528CA21f23b02F4Cf5AE5dDf7CEd113D6df2138
  /// ReputationModule: 0xB163BE6EC963471c533eB65451F35E117d3DcBf0
  /// ConstantLikertEnforcement: 0xc14961b3898abef2D4aC9C6B2E3817341DaA9E0d
  /// PayCurve: 0xc4ae694e97EC1B91CBa46FC7473eB0F28a9B6F08

    const laborMarket = await ethers.getContractAt("LaborMarket", "0x14A2Eb1fC0275455B121c483Cc8818B5F659e916");
    const factory = await ethers.getContractAt("LaborMarketNetwork", "0xd528CA21f23b02F4Cf5AE5dDf7CEd113D6df2138");
    const reputationModule = await ethers.getContractAt("ReputationModule", "0xB163BE6EC963471c533eB65451F35E117d3DcBf0");
    const enforcementModule = await ethers.getContractAt("ConstantLikertEnforcement", "0xc14961b3898abef2D4aC9C6B2E3817341DaA9E0d");
    const payCurve = await ethers.getContractAt("PayCurve", "0xc4ae694e97EC1B91CBa46FC7473eB0F28a9B6F08");

    const contracts = [
    {
      contract: laborMarket, 
      args: [], 
      name: "LaborMarket",
      address: laborMarket.address
    },
    {
      contract: factory, 
      args: [laborMarket.address, ethers.constants.AddressZero, [0x854DE1bf96dFBe69FC46f1a888d26934Ad47B77f, 0], [0x854DE1bf96dFBe69FC46f1a888d26934Ad47B77f, 1]], 
      name: "LaborMarketNetwork",
      address: factory.address
    },
    {
      contract: enforcementModule, 
      args: [], 
      name: "ConstantLikertEnforcement",
      address: "0xA49d7AE1aa90e384704749Ea78093577a70cD87c"
    },
    {
      contract: reputationModule, 
      args: [factory.address], 
      name: "ReputationModule",
      address: "0xcb2241adD515189b661423E04d9917fFDb90CD01"
    },
    {
      contract: payCurve, 
      args: [], 
      name: "PayCurve",
      address: payCurve.address
    },
  ]

  for (const contract of contracts) {
    await hre.run("verify:verify", {
      address: contract.contract.address,
      constructorArguments: contract.args,
    });
    await new Promise(r => setTimeout(r, 30000));
    console.log(`✅ ${contract.name} Verified.`)
  }
}

verify();