const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

async function main(verify) {
    const [deployer] = await ethers.getSigners();
    const balance = ethers.utils.formatEther(await deployer.getBalance());
    const chainId = hre.network.config.chainId;

    const governorBadgeAddress = "0xA873Dad23D357a19ac03CdA4ea3522108D26ebeA";
    const governorBadgeTokenId = 3;
    
    console.table({
        "Deployer Address": deployer.address,
        "Deployer Balance": balance,
        "Chain ID": chainId
    })

    const LaborMarket = await ethers.getContractFactory("LaborMarket");
    let laborMarket = await LaborMarket.deploy();
    laborMarket = await laborMarket.deployed();
    console.log("✅ LaborMarket Deployed.")


    const NetworkArgs = [laborMarket.address, ethers.constants.AddressZero, governorBadgeAddress, governorBadgeTokenId]
    const LaborMarketNetwork = await ethers.getContractFactory("LaborMarketNetwork");
    let network = await LaborMarketNetwork.deploy(
        ...NetworkArgs
    );
    network = await network.deployed();
    console.log("✅ LaborMarketNetwork Deployed.")


    const LikertEnforcement = await ethers.getContractFactory("LikertEnforcementCriteria");
    let enforcementModule = await LikertEnforcement.deploy();
    enforcementModule = await enforcementModule.deployed();
    console.log("✅ Enforcement Module Deployed.")

    
    const ReputationModuleArgs = [network.address]
    const ReputationModule = await ethers.getContractFactory("ReputationModule");
    let reputationModule = await ReputationModule.deploy(
        ...ReputationModuleArgs
    );
    reputationModule = await reputationModule.deployed();
    console.log("✅ Reputation Module Deployed.")


    const PayCurve = await ethers.getContractFactory("PayCurve");
    let payCurve = await PayCurve.deploy();
    payCurve = await payCurve.deployed();
    console.log("✅ Pay Curve Deployed.")

    console.table({
        "LaborMarketImplementation Address": laborMarket.address,
        "LaborMarketNetwork Address": network.address,
        "EnforcementModule Address": enforcementModule.address,
        "ReputationModule Address": reputationModule.address,
        "PayCurve Address": payCurve.address
    })

    
    if (verify === true && chainId !== 31337 && chainId !== 1337) {
      const contracts = [
        {
          address: laborMarket.address, args: [], name: "LaborMarket"
        },
        {
          address: network.address, args: NetworkArgs, name: "LaborMarketNetwork"
        },
        {
          address: enforcementModule.address, args: [], name: "LikertEnforcementCriteria"
        },
        {
          address: reputationModule.address, args: ReputationModuleArgs, name: "ReputationModule"
        },
        {
          address: payCurve.address, args: [], name: "PayCurve"
        },
      ]

      await new Promise(r => setTimeout(r, 30000));
      for (const contract of contracts) {
        await hre.run("verify:verify", {
          address: contract.address,
          constructorArguments: contract.args,
        });
        await new Promise(r => setTimeout(r, 30000));
        console.log(`✅ ${contract.name} Verified.`)
      }
    }
}

main(true);