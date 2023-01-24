const { assert } = require('chai')

require('chai')
    .use(require('chai-as-promised'))
    .should()

const { ethers } = require("hardhat");

interface LaborMarketConfiguration {
    marketUri: string,
    modules: {
        enforcement: string,
        reputation: string,
        payment: string,
        network: string
    },
    delegate: {
        token: string,
        tokenId: number
    },
    maintainer: {
        token: string,
        tokenId: number
    }
    reputation: {
        token: string,
        tokenId: number
    },
    signalStake: number,
    submitMin: number,
    submitMax: number
}

describe("Badger", function () {
    before(async () => {
        const [deployer] = await ethers.getSigners();
        
        const BadgerOrganization = await ethers.getContractFactory("BadgerOrganization");
        let badgerOrganization = await BadgerOrganization.deploy();
        badgerOrganization = await badgerOrganization.deployed();

        const Badger = await ethers.getContractFactory("Badger");
        let badger = await Badger.deploy(badgerOrganization.address);
        badger = await badger.deployed();

        const reputationToken = await badger.createOrganization(
            badgerOrganization.address,
            deployer.address,
            "ipfs",
            "ipfs",
            "MDAO",
            "MDAO"
        );

        console.log(reputationToken, typeof reputationToken);

        // const LaborMarket = await ethers.getContractFactory("LaborMarket");
        // let laborMarket = await LaborMarket.deploy();
        // laborMarket = await laborMarket.deployed();


        // const NetworkArgs = [laborMarket.address, ethers.constants.AddressZero, s, s]
        // const LaborMarketNetwork = await ethers.getContractFactory("LaborMarketNetwork");
        // let network = await LaborMarketNetwork.deploy(
        //     ...NetworkArgs
        // );
        // network = await network.deployed();

        // const LikertEnforcement = await ethers.getContractFactory("LikertEnforcementCriteria");
        // let enforcementModule = await LikertEnforcement.deploy();
        // enforcementModule = await enforcementModule.deployed();


        // const ReputationModuleArgs = [network.address]
        // const ReputationModule = await ethers.getContractFactory("ReputationModule");
        // let reputationModule = await ReputationModule.deploy(
        //     ...ReputationModuleArgs
        // );
        // reputationModule = await reputationModule.deployed();

        // const PaymentModule = await ethers.getContractFactory("PaymentModule");
        // let paymentModule = await PaymentModule.deploy();
        // paymentModule = await paymentModule.deployed();

        // const PayCurve = await ethers.getContractFactory("PayCurve");
        // let payCurve = await PayCurve.deploy();
        // payCurve = await payCurve.deployed();
    });

    it("Set Up", async () => {
        
    })
})