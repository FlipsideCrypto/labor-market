const hre = require('hardhat');
const { assert } = require('chai');
require('chai').use(require('chai-as-promised')).should();

const { ethers } = require('hardhat');

const { mine } = require('@nomicfoundation/hardhat-network-helpers');

interface ServiceRequest {
    serviceRequester: string;
    pToken: string;
    pTokenQ: number;
    rTokenQ: number;
    signalExp: number;
    submissionExp: number;
    enforcementExp: number;
    submissionCount: number;
    uri: string;
}

interface LaborMarketConfiguration {
    marketUri: string;
    modules: {
        enforcement: string;
        reputation: string;
        payment: string;
        network: string;
    };
    delegate: {
        token: string;
        tokenId: number;
    };
    maintainer: {
        token: string;
        tokenId: number;
    };
    reputation: {
        token: string;
        tokenId: number;
    };
    signalStake: number;
    submitMin: number;
    submitMax: number;
}

async function getCurrentBlockTimestamp() {
    return hre.ethers.provider.getBlock('latest').then((block: any) => block.timestamp);
}

describe('Reputation', function () {
    let deployer: any;
    let signer1: any;
    let signer2: any;

    const GOVERNOR_TOKEN_ID = 0;
    const DELEGATE_TOKEN_ID = 1;
    const MAINTAINER_TOKEN_ID = 2;
    const REPUTATION_TOKEN_ID = 3;

    var laborMarket: any;
    var payToken: any;
    var repToken: any;
    var network: any;
    var reputationModule: any;
    var enforcementModule: any;
    var payCurve: any;
    var market: any;

    before(async () => {
        [deployer, signer1, signer2] = await ethers.getSigners();
        const BadgerOrganization = await ethers.getContractFactory('BadgerOrganization');
        var badgerOrganization = await BadgerOrganization.deploy();
        badgerOrganization = await badgerOrganization.deployed();

        const Badger = await ethers.getContractFactory('Badger');
        var badger = await Badger.deploy(badgerOrganization.address);
        badger = await badger.deployed();

        const reputationToken = await badger.createOrganization(
            badgerOrganization.address,
            deployer.address,
            'ipfs',
            'ipfs',
            'MDAO',
            'MDAO',
        );
        const tx = await reputationToken.wait();
        repToken = BadgerOrganization.attach(tx.events[4].args[0]);

        const PaymentToken = await ethers.getContractFactory('ERC20FreeMint');
        payToken = await PaymentToken.deploy();
        payToken = await payToken.deployed();

        const LaborMarket = await ethers.getContractFactory('LaborMarket');
        laborMarket = await LaborMarket.deploy();
        laborMarket = await laborMarket.deployed();

        const NetworkArgs = [laborMarket.address, ethers.constants.AddressZero, repToken.address, GOVERNOR_TOKEN_ID];
        const LaborMarketNetwork = await ethers.getContractFactory('LaborMarketNetwork');
        network = await LaborMarketNetwork.deploy(...NetworkArgs);
        network = await network.deployed();

        const LikertEnforcement = await ethers.getContractFactory('Best5EnforcementCriteria');
        enforcementModule = await LikertEnforcement.deploy();
        enforcementModule = await enforcementModule.deployed();

        const PayCurve = await ethers.getContractFactory('PayCurve');
        payCurve = await PayCurve.deploy();
        payCurve = await payCurve.deployed();

        const ReputationModuleArgs = [network.address];
        const ReputationModule = await ethers.getContractFactory('ReputationModule');
        reputationModule = await ReputationModule.deploy(...ReputationModuleArgs);
        reputationModule = await reputationModule.deployed();
    });

    describe('Set Up', async () => {
        it('Setting up Badges', async () => {
            const paymentKey1155 = ethers.utils.solidityKeccak256(
                ['address', 'uint256'],
                [ethers.constants.AddressZero, 0],
            );
            for (let i = 0; i < 4; i++) {
                await repToken
                    .connect(deployer)
                    .setBadge(
                        i,
                        false,
                        true,
                        deployer.address,
                        'ipfs',
                        [paymentKey1155, 0],
                        [reputationModule.address],
                    );
            }

            await repToken.leaderMint(deployer.address, GOVERNOR_TOKEN_ID, 1, '0x');

            await repToken.leaderMint(deployer.address, DELEGATE_TOKEN_ID, 1, '0x');

            await repToken.leaderMintBatch(
                [deployer.address, signer1.address, signer2.address],
                REPUTATION_TOKEN_ID,
                [100, 100, 100],
                '0x',
            );

            await repToken.leaderMintBatch(
                [deployer.address, signer1.address, signer2.address],
                MAINTAINER_TOKEN_ID,
                [1, 1, 1],
                '0x',
            );

            await payToken.freeMint(deployer.address, 1000000000);
        });
        it('Set up Market and Request', async () => {
            const marketConfig = <LaborMarketConfiguration>{
                marketUri: 'ipfs',
                modules: {
                    enforcement: enforcementModule.address,
                    reputation: reputationModule.address,
                    payment: payCurve.address,
                    network: network.address,
                },
                delegate: {
                    token: repToken.address,
                    tokenId: DELEGATE_TOKEN_ID,
                },
                maintainer: {
                    token: repToken.address,
                    tokenId: MAINTAINER_TOKEN_ID,
                },
                reputation: {
                    token: repToken.address,
                    tokenId: REPUTATION_TOKEN_ID,
                },
                signalStake: 5,
                submitMin: 0,
                submitMax: 1000000000,
            };

            market = await network.createLaborMarket(laborMarket.address, deployer.address, marketConfig);
            market = await market.wait();
            market = laborMarket.attach(market.events[3].args['marketAddress']);

            const timestamp = (await getCurrentBlockTimestamp()) + 1000;
            await payToken.approve(market.address, 1000000000);

            var request = await market.connect(deployer).submitRequest(
                payToken.address, // _pToken
                1000, // _pTokenQ
                100, // _rTokenQ
                timestamp, // _signalExp
                timestamp, // _submissionExp
                timestamp, // _enforcementExp
                'ipfs', // _requestUri
            );
        });
        it('Set up Response', async () => {
            await market.connect(signer1).signal(1);
            await market.connect(signer2).signal(1);

            await market.connect(signer1).provide(1, '0x');
            await market.connect(signer2).provide(1, '0x');

            await market.connect(deployer).signalReview(
                1, // requestId
                2, // amount
            );

            await market.connect(deployer).review(
                1, // requestId
                2, // submissionId
                1, // score
            );
            await market.connect(deployer).review(
                1, // requestId
                3, // submissionId
                2, // score
            );
        });
        it('Check payouts', async () => {});
    });
});
