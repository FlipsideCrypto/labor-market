const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
//     LaborMarketImplementation Address │ '0xB9464209bEeb537050A5278AEB4E450E7C0Bed0A' │
// │    LaborMarketFactory Address     │ '0x6EbBE4A8c2F58bDB59F906Cb1Fc5A14B2bF5471C' │
// │     EnforcementModule Address     │ '0xA49d7AE1aa90e384704749Ea78093577a70cD87c' │
// │     ReputationModule Address      │ '0xcb2241adD515189b661423E04d9917fFDb90CD01' │
// │       PaymentModule Address       │ '0x83e16f89627B1Ce73F5000c1225f4673a2Cf3deB' │
// │         PayCurve Address          │ '0x67bf50b4688Ff31194C74084D8c0903F59cb098B' │
// │           ERC20 Address           │ '0xD1Dee0DD6C89FB4d902818C54DD88B3555Ad7df2' │
// │          ERC1155 Address          │ '0x0034F6CF1ec2A5b51497D06C0619985945F6A5d4' │
// │     Reputation Engine Address     │ '0x1585c93cf4F74230F6dC4378cDa2B98187A4A40E'

    const laborMarket = await ethers.getContractAt("LaborMarket", "0xB9464209bEeb537050A5278AEB4E450E7C0Bed0A");
    const factory = await ethers.getContractAt("LaborMarketNetwork", "0x6EbBE4A8c2F58bDB59F906Cb1Fc5A14B2bF5471C");
    const enforcementModule = await ethers.getContractAt("LikertEnforcementCriteria", "0xA49d7AE1aa90e384704749Ea78093577a70cD87c");
    const reputationModule = await ethers.getContractAt("ReputationModule", "0xcb2241adD515189b661423E04d9917fFDb90CD01");
    const paymentModule = await ethers.getContractAt("PaymentModule", "0x83e16f89627B1Ce73F5000c1225f4673a2Cf3deB");
    const payCurve = await ethers.getContractAt("PayCurve", "0x67bf50b4688Ff31194C74084D8c0903F59cb098B");
    const erc20 = await ethers.getContractAt("ERC20", "0xD1Dee0DD6C89FB4d902818C54DD88B3555Ad7df2");
    const erc1155 = await ethers.getContractAt("ERC1155", "0x0034F6CF1ec2A5b51497D06C0619985945F6A5d4");
    const reputationEngine = await ethers.getContractAt("ReputationEngine", "0xb0B8a38460A53c5CAc3650B8De8DD85016847D1e");

    const contracts = [
    {
      contract: laborMarket, 
      args: [], 
      name: "LaborMarket",
      address: "0xB9464209bEeb537050A5278AEB4E450E7C0Bed0A"
    },
    {
      contract: factory, 
      args: [laborMarket.address, ethers.constants.AddressZero], 
      name: "LaborMarketFactory",
      address: "0x6EbBE4A8c2F58bDB59F906Cb1Fc5A14B2bF5471C"
    },
    {
      contract: enforcementModule, 
      args: [], 
      name: "LikertEnforcementCriteria",
      address: "0xA49d7AE1aa90e384704749Ea78093577a70cD87c"
    },
    {
      contract: reputationModule, 
      args: [factory.address], 
      name: "ReputationModule",
      address: "0xcb2241adD515189b661423E04d9917fFDb90CD01"
    },
    {
      contract: paymentModule, 
      args: [], 
      name: "PaymentModule",
      address: "0x83e16f89627B1Ce73F5000c1225f4673a2Cf3deB"
    },
    {
      contract: payCurve, 
      args: [], 
      name: "PayCurve",
      address: "0x67bf50b4688Ff31194C74084D8c0903F59cb098B"
    },
    {
      contract: erc20, 
      args: [], 
      name: "ERC20FreeMint",
      address: "0xD1Dee0DD6C89FB4d902818C54DD88B3555Ad7df2"
    },
    {
      contract: erc1155, 
      args: [], 
      name: "ERC1155FreeMint",
      address: "0x0034F6CF1ec2A5b51497D06C0619985945F6A5d4"
    },
    {
      contract: reputationEngine, 
      args: [], 
      name: "ReputationEngine",
      address: "0xb0B8a38460A53c5CAc3650B8De8DD85016847D1e"
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

main();