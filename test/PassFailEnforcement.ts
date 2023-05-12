const hre = require('hardhat');
const { assert, expect } = require('chai');
const { loadFixture, mine } = require('@nomicfoundation/hardhat-network-helpers');

require('chai').use(require('chai-as-promised')).should();

const ethers = hre.ethers;

import type { Wallet } from 'ethers';
import type { LaborMarketInterface } from '../package/types/src/LaborMarket';

// Utility to get the current hardhat block timestamp
async function getCurrentBlockTimestamp() {
    return hre.ethers.provider.getBlock('latest').then((block: any) => block.timestamp);
}

// Get an amount of signers funded with hardhat eth.
async function getRandomSigners(amount: number): Promise<Wallet[]> {
    const signers: Wallet[] = [];
    for (let i = 0; i < amount; i++) {
        signers.push(ethers.Wallet.createRandom().connect(hre.ethers.provider));
    }

    // Give accounts hardhat eth
    await Promise.all(
        signers.map((signer: Wallet) => {
            hre.ethers.provider.send('hardhat_setBalance', [signer.address, '0xFFFFFFFFFFFFFF']);
        }),
    );

    return signers;
}

describe('Pass Fail Enforcement', function () {
    async function deployMulticall() {
        const Multicall = await ethers.getContractFactory('Multicall3Mock');
        const multicall = await Multicall.deploy();
        return await multicall.deployed();
    }

    async function deployCoins() {
        const [deployer] = await ethers.getSigners();

        const ERC20 = await ethers.getContractFactory('ERC20FreeMint');

        const [PEPE, wETH, NEAR, USDC] = await Promise.all([
            ERC20.deploy('PEPE', 'PEPE', 18),
            ERC20.deploy('ETH', 'ETH', 18),
            ERC20.deploy('NEAR', 'NEAR', 18),
            ERC20.deploy('USDC', 'USDC', 18),
        ]);

        const [pepe, weth, near, usdc] = await Promise.all([
            PEPE.deployed(),
            wETH.deployed(),
            NEAR.deployed(),
            USDC.deployed(),
        ]);

        const [pepeMint, wethMint, nearMint, usdcMint] = await Promise.all([
            pepe.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
            weth.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
            near.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
            usdc.freeMint(deployer.address, ethers.utils.parseEther('1000000')),
        ]);

        await Promise.all([pepeMint.wait(), wethMint.wait(), nearMint.wait(), usdcMint.wait()]);

        return { pepe, weth, near, usdc };
    }

    async function deployLaborMarketSingleton() {
        const ERC20s = await loadFixture(deployCoins);

        const LaborMarket = await ethers.getContractFactory('LaborMarket');
        const laborMarketSingleton = await LaborMarket.deploy();
        await laborMarketSingleton.deployed();

        return { laborMarketSingleton, ERC20s };
    }

    async function deployFactory() {
        const { laborMarketSingleton, ERC20s } = await loadFixture(deployLaborMarketSingleton);

        const Factory = await ethers.getContractFactory('LaborMarketFactory');
        const factory = await Factory.deploy(laborMarketSingleton.address);
        await factory.deployed();

        const EnforcementCriteria = await ethers.getContractFactory('ScalableEnforcement');
        const enforcement = await EnforcementCriteria.deploy();
        await enforcement.deployed();

        return { factory, enforcement, laborMarketSingleton, ERC20s };
    }

    async function createMarket(auxilaries: number[] = [1], alphas: number[] = [0, 1], betas: number[] = [0, 1]) {
        const { factory, enforcement, ERC20s } = await loadFixture(deployFactory);
        const [deployer] = await ethers.getSigners();

        const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
        const sigs: any = [];
        const nodes: any = [];

        const args = [
            deployer.address, // address _deployer,
            criteria, // EnforcementCriteriaInterface _criteria,
            auxilaries, // uint256[] memory _auxilaries,
            alphas, // uint256[] memory _alphas,
            betas, // uint256[] memory _betas
            sigs, // bytes4[] memory _sigs,
            nodes, // Node[] memory _nodes,
        ];

        const tx = await factory.createLaborMarket(...args);
        const receipt = await tx.wait();

        const event = receipt.events.find((e: any) => e.event === 'LaborMarketCreated');

        const marketAddress = event.args.marketAddress;

        const market = await ethers.getContractAt('LaborMarket', marketAddress);

        const [pepeApproval, usdcApproval] = await Promise.all([
            ERC20s.pepe.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
            ERC20s.usdc.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
        ]);

        await Promise.all([pepeApproval.wait(), usdcApproval.wait()]);

        return { market, factory, enforcement, deployer, ERC20s };
    }

    describe('Pass Fail Enforcement', async () => {
        it('Pass Fail', async () => {
            // Market Parameters
            const providerLimit = 20;
            const reviewerLimit = 100;
            // Outcome parameters
            const participatingProviders = 10;
            const participatingReviewers = 10;

            // Pass Fail Enforcement:
            // Max Value: 1
            // Possible Scores: 0, 1
            // Weights: 0, 1
            const passFailConfig = [[1], [0, 1], [0, 1]];

            const { market, ERC20s, enforcement } = await createMarket(...passFailConfig);
            const multicall = await loadFixture(deployMulticall);

            // initialize signer arrays
            const reviewers = await getRandomSigners(participatingReviewers);
            const providers = await getRandomSigners(participatingProviders);

            // Create a pass fail request
            const now = await getCurrentBlockTimestamp();

            const request: LaborMarketInterface.ServiceRequestStruct = {
                signalExp: now + 1000, // uint48
                submissionExp: now + 2000, // uint48
                enforcementExp: now + 3000, // uint48
                providerLimit: providerLimit, // uint64
                reviewerLimit: reviewerLimit, // uint64
                pTokenProviderTotal: ethers.utils.parseEther('100'), // uint256
                pTokenReviewerTotal: ethers.utils.parseEther('100'), // uint256
                pTokenProvider: ERC20s.pepe.address, // IERC20
                pTokenReviewer: ERC20s.usdc.address, // IERC20
            };

            // submit request
            const tx = await market.submitRequest(0, request, 'uri');
            const receipt = await tx.wait();

            const requestId = receipt.events.find((e: any) => e.event === 'RequestConfigured').args.requestId;

            // signal
            const signals = await Promise.all(
                providers.map((provider: any) => market.connect(provider).signal(requestId)),
            );
            await Promise.all(signals.map((signal) => signal.wait()));

            // submit
            const submissionsTx = await Promise.all(
                providers.map((provider: any) => market.connect(provider).provide(requestId, 1)),
            );
            const submissionReceipts = await Promise.all(submissionsTx.map((submission) => submission.wait()));

            // get submissions
            const submissions = submissionReceipts.map((receipt: any) => {
                const event = receipt.events.find((e: any) => e.event === 'RequestFulfilled');
                return {
                    id: event.args.submissionId,
                    provider: providers.find((provider) => provider.address === event.args.fulfiller),
                    scores: reviewers.map(() => Number(Math.random() > 0.5 ? 1 : 0)),
                };
            });

            // signal reviews
            const reviewSignals = await Promise.all(
                reviewers.map((reviewer: any) =>
                    market
                        .connect(reviewer)
                        .signalReview(requestId, Math.floor(reviewerLimit / participatingReviewers)),
                ),
            );
            await Promise.all(reviewSignals.map((reviewSignal) => reviewSignal.wait()));

            // review each submission
            for (const provider of providers) {
                const submission = submissions.find(
                    (submission: any) => submission.provider.address === provider.address,
                );
                const reviews = await Promise.all(
                    reviewers.map((reviewer: any, idx: number) =>
                        market.connect(reviewer).review(requestId, submission?.id, submission?.scores[idx], '0x'),
                    ),
                );
                await Promise.all(reviews.map((review) => review.wait()));
            }

            /*
            // TODO: Fix this and replace above. A tx is failing somewhere.
            // Build review calldata
            const reviewerCalldata = reviewers.map((reviewer: any, idx: number) => {
                return submissions.map((submission) => {
                    return market.interface.encodeFunctionData('review', [
                        requestId,
                        submission.id,
                        submission.scores[idx],
                        '0x',
                    ]);
                });
            });

            // Build multicall calldata
            const multicallData = reviewerCalldata.map((data: any) => {
                return data.map((call: any) => {
                    return {
                        target: market.address,
                        allowFailure: false,
                        callData: call,
                    };
                });
            });

            // review
            const reviews = await Promise.all(
                multicallData.map((data, idx: number) => {
                    return multicall.connect(reviewers[idx]).aggregate3(data);
                }),
            );
            await reviews.map((review) => review.wait());
            */

            // skip ahead in time
            await mine(ethers.BigNumber.from(request.enforcementExp).sub(ethers.BigNumber.from(now)).toNumber() + 1);

            // Payment Checking
            const rewards = await Promise.all(
                submissions.map((submission) =>
                    enforcement.callStatic.getRewards(market.address, requestId, submission.id),
                ),
            );

            console.table({
                reward: rewards.map((reward) => ethers.utils.formatEther(reward)),
                avgScore: submissions.map((submission) => submission.scores.reduce((a, b) => a + b, 0) / 10),
            });

            console.log(
                'Unpaid',
                ethers.utils.formatEther(await enforcement.callStatic.getRemainder(market.address, requestId)),
            );

            const balanceOfContract = await ERC20s.pepe.balanceOf(market.address);
            console.log('Balance of contract', ethers.utils.formatEther(balanceOfContract));

            // const balancesBefore = await Promise.all(
            //     providers.map((provider) => ERC20s.pepe.balanceOf(provider.address)),
            // );

            // const claims = await Promise.all(
            //     submissions.map((submission) => {
            //         return market.connect(submission.provider).claim(requestId, submission.id);
            //     }),
            // );
            // await claims.map((claim) => claim.wait());

            // const balancesAfter = await Promise.all(
            //     providers.map((provider) => ERC20s.pepe.balanceOf(provider.address)),
            // );

            // const balancesDiff = balancesAfter.map((balance, idx) => {
            //     return balance.sub(balancesBefore[idx]);
            // });

            // console.log('balancesDiff', balancesDiff);
        });
    });
});
