const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

async function main(verify) {
    await hre.run("compile");
    const [deployer] = await ethers.getSigners();
    const chainId = hre.network.config.chainId;
    
    console.table({
        "Deployer Address": deployer.address,
        "Deployer Balance": (await deployer.getBalance()).toString(),
        "Chain ID": chainId
    })

    const LaborMarket = await ethers.getContractFactory("LaborMarket");
    let laborMarket = await LaborMarket.deploy();
    laborMarket = await laborMarket.deployed();
    console.log("✅ LaborMarket Deployed.")


    const LaborMarketFactory = await ethers.getContractFactory("LaborMarketNetwork");
    let factory = await LaborMarketFactory.deploy(
        laborMarket.address,
        ethers.constants.AddressZero,
    );
    factory = await factory.deployed();
    console.log("✅ LaborMarketFactory Deployed.")


    const LikertEnforcement = await ethers.getContractFactory("LikertEnforcementCriteria");
    let enforcementModule = await LikertEnforcement.deploy();
    enforcementModule = await enforcementModule.deployed();
    console.log("✅ Enforcement Module Deployed.")


    const ReputationModule = await ethers.getContractFactory("ReputationModule");
    let reputationModule = await ReputationModule.deploy(
        factory.address,
    );
    reputationModule = await reputationModule.deployed();
    console.log("✅ Reputation Module Deployed.")


    const PaymentModule = await ethers.getContractFactory("PaymentModule");
    let paymentModule = await PaymentModule.deploy();
    paymentModule = await paymentModule.deployed();
    console.log("✅ Payment Module Deployed.")


    const PayCurve = await ethers.getContractFactory("PayCurve");
    let payCurve = await PayCurve.deploy();
    payCurve = await payCurve.deployed();


    const ERC20 = await ethers.getContractFactory("ERC20FreeMint");
    let erc20 = await ERC20.deploy();
    erc20 = await erc20.deployed();
    console.log("✅ ERC20 Deployed.")


    const ERC1155 = await ethers.getContractFactory("ERC1155FreeMint");
    let erc1155 = await ERC1155.deploy();
    erc1155 = await erc1155.deployed();
    console.log("✅ ERC1155 Deployed.")


    const ReputationEngineMaster = await ethers.getContractFactory("ReputationEngine");
    let reputationEngineMaster = await ReputationEngineMaster.deploy();
    reputationEngineMaster = await reputationEngineMaster.deployed();
    console.log("✅ Reputation Engine Deployed.")


    const ReputationEngine = await reputationModule.createReputationEngine(
        reputationEngineMaster.address,
        erc1155.address,
        0,
        0,
        0,
    );
    const tx = await ReputationEngine.wait();
    const reputationEngineAddress = tx.events[1].args[0];
    console.log("✅ Reputation Engine Deployed.")


    console.table({
        "LaborMarketImplementation Address": laborMarket.address,
        "LaborMarketFactory Address": factory.address,
        "EnforcementModule Address": enforcementModule.address,
        "ReputationModule Address": reputationModule.address,
        "PaymentModule Address": paymentModule.address,
        "PayCurve Address": payCurve.address,
        "ERC20 Address": erc20.address,
        "ERC1155 Address": erc1155.address,
        "Reputation Engine Address": reputationEngineAddress,
    })

    
    if (verify === true && (chainId != 31337 || chainId != 1337)) {
      const contracts = [
        {
          contract: laborMarket, args: [], name: "LaborMarket"
        },
        {
          contract: factory, args: [laborMarket.address, ethers.constants.AddressZero], name: "LaborMarketFactory"
        },
        {
          contract: enforcementModule, args: [], name: "LikertEnforcementCriteria"
        },
        {
          contract: reputationModule, args: [factory.address], name: "ReputationModule"
        },
        {
          contract: paymentModule, args: [], name: "PaymentModule"
        },
        {
          contract: payCurve, args: [], name: "PayCurve"
        },
        {
          contract: erc20, args: [], name: "ERC20FreeMint"
        },
        {
          contract: erc1155, args: [], name: "ERC1155FreeMint"
        },
        {
          contract: reputationEngineMaster, args: [], name: "ReputationEngine"
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
}

main(true);