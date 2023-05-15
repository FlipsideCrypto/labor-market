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
            //////////////////////////
            //        CONFIG        //
            //////////////////////////

            // Market Parameters
            const providerLimit = 20;
            const reviewerLimit = 100;
            const pTokenProviderTotal = ethers.utils.parseEther('100000');
            const pTokenReviewerTotal = ethers.utils.parseEther('1000');

            // Outcome parameters
            const participatingProviders = 8;
            const participatingReviewers = 4;

            // Pass Fail Enforcement:
            // Max Value: 1
            // Possible Scores: 0, 1
            // Weights: 0, 1
            const possibleScores = [0, 1];
            const weights = [0, 1];

            const reviewsPerReviewer = Math.floor(reviewerLimit / participatingReviewers);

            //////////////////////////

            const { market, ERC20s, enforcement, deployer } = await createMarket(
                [Math.max(...possibleScores)],
                possibleScores,
                weights,
            );

            // Create a pass fail request
            const now = await getCurrentBlockTimestamp();

            // Configure the request
            const request: LaborMarketInterface.ServiceRequestStruct = {
                signalExp: now + 1000, // uint48
                submissionExp: now + 2000, // uint48
                enforcementExp: now + 3000, // uint48
                providerLimit: providerLimit, // uint64
                reviewerLimit: reviewerLimit, // uint64
                pTokenProviderTotal: pTokenProviderTotal, // uint256
                pTokenReviewerTotal: pTokenReviewerTotal, // uint256
                pTokenProvider: ERC20s.pepe.address, // IERC20
                pTokenReviewer: ERC20s.usdc.address, // IERC20
            };

            // initialize signer arrays
            const reviewers = await getRandomSigners(participatingReviewers);
            const providers = await getRandomSigners(participatingProviders);

            // Get balances before all the actions
            const balancesBefore = {
                providers: await Promise.all(providers.map((provider) => ERC20s.pepe.balanceOf(provider.address))),
                reviewers: await Promise.all(reviewers.map((reviewer) => ERC20s.usdc.balanceOf(reviewer.address))),
                deployerPepe: await ERC20s.pepe.balanceOf(deployer.address),
                deployerUsdc: await ERC20s.usdc.balanceOf(deployer.address),
                marketPepe: await ERC20s.pepe.balanceOf(market.address),
                marketUsdc: await ERC20s.usdc.balanceOf(market.address),
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
                reviewers.map((reviewer: any) => market.connect(reviewer).signalReview(requestId, reviewsPerReviewer)),
            );
            await Promise.all(reviewSignals.map((reviewSignal) => reviewSignal.wait()));

            // review each submission
            let reviewPromises: any = [];

            for (const submission of submissions) {
                // await the call to increment the nonce
                const submissionReviews = await Promise.all(
                    reviewers.map((reviewer: any, idx: number) =>
                        market.connect(reviewer).review(requestId, submission.id, submission.scores[idx], '0x'),
                    ),
                );

                reviewPromises = [...reviewPromises, ...submissionReviews];
            }
            await Promise.all(reviewPromises.map((review: any) => review.wait()));

            // skip ahead in time
            await mine(ethers.BigNumber.from(request.enforcementExp).sub(ethers.BigNumber.from(now)).toNumber() + 1);

            // Payment Checking
            const rewards = await Promise.all(
                submissions.map((submission) =>
                    enforcement.callStatic.getRewards(market.address, requestId, submission.id),
                ),
            );

            // total earned by providers
            const totalRewards = rewards.reduce((a, b) => a.add(b), ethers.BigNumber.from('0'));

            console.table({
                'Review Count': submissions.map((submission) => submission.scores.length),
                'Average Score': submissions.map((submission) => submission.scores.reduce((a, b) => a + b, 0) / 10),
                'Reward': rewards.map((reward) => ethers.utils.formatEther(reward)),
            });

            // Run the claim transactions. Filter
            const claims = await Promise.all(
                submissions
                    // .filter((submission) => submission.scores.reduce((a, b) => a + b, 0) > 0)
                    .map((submission) => {
                        return market.connect(submission.provider).claim(requestId, submission.id);
                    }),
            );
            await claims.map((claim) => claim.wait());

            // total tokens unused on less submissions than the limit
            // total / limit * (limit - participating)
            const unusedProviderTokens = pTokenProviderTotal
                .div(ethers.BigNumber.from(providerLimit))
                .mul(ethers.BigNumber.from(providerLimit).sub(ethers.BigNumber.from(participatingProviders)));

            // total remainder for the requester
            const totalProviderTokenRemainder = pTokenProviderTotal.sub(totalRewards);

            // total reviews on the request
            const totalReviews = submissions.reduce((a, b) => a + b.scores.length, 0);

            // payment per reviewer
            const paymentPerReviewer = pTokenReviewerTotal.div(ethers.BigNumber.from(reviewerLimit));

            // Unused reviewer pTokens
            const totalReviewerTokenRemainder = pTokenReviewerTotal.sub(
                paymentPerReviewer.mul(ethers.BigNumber.from(totalReviews)),
            );

            // Log our table for sanity
            console.table({
                'Provider Rewards': ethers.utils.formatEther(totalRewards),
                'Provider Remainders': ethers.utils.formatEther(totalProviderTokenRemainder.sub(unusedProviderTokens)),
                'Unused Provider Tokens': ethers.utils.formatEther(unusedProviderTokens),
                'Provider Token Remainder': ethers.utils.formatEther(totalProviderTokenRemainder),
                'Reviewer Token Remainder': ethers.utils.formatEther(totalReviewerTokenRemainder),
            });

            // Run the claim remainder transaction
            const claimRemainder = await market.connect(deployer).claimRemainder(requestId);
            await claimRemainder.wait();

            // Get balances after all the actions.
            const balancesAfter = {
                providers: await Promise.all(providers.map((provider) => ERC20s.pepe.balanceOf(provider.address))),
                reviewers: await Promise.all(reviewers.map((reviewer) => ERC20s.usdc.balanceOf(reviewer.address))),
                deployerPepe: await ERC20s.pepe.balanceOf(deployer.address),
                deployerUsdc: await ERC20s.usdc.balanceOf(deployer.address),
                marketPepe: await ERC20s.pepe.balanceOf(market.address),
                marketUsdc: await ERC20s.usdc.balanceOf(market.address),
            };

            // Every provider received the right amount in their claim.
            assert(
                balancesAfter.providers.every(
                    (balance, idx: number) =>
                        balance.sub(balancesBefore.providers[idx]).sub(rewards[idx]).toString() === '0',
                ),
                'PassFail: Providers did not receive reward',
            );

            // Every reviewer received the right amount.
            assert(
                balancesAfter.reviewers.every((balance, idx: number) =>
                    balance.sub(balancesBefore.reviewers[idx]).eq(paymentPerReviewer.mul(submissions.length)),
                ),
                'PassFail: Reviewers did not receive reward',
            );

            // Make sure deployer was refunded unused pTokens.
            assert(
                balancesBefore.deployerPepe.sub(balancesAfter.deployerPepe).eq(totalRewards),
                'PassFail: Deployer did not receive provider pToken remainder',
            );

            assert(
                balancesBefore.deployerUsdc
                    .sub(balancesAfter.deployerUsdc)
                    .eq(pTokenReviewerTotal.sub(totalReviewerTokenRemainder)),
                'PassFail: Deployer did not receive reviewer pToken remainder',
            );

            // Make sure contract is fully paid out.
            assert(balancesAfter.marketPepe.eq(0), 'PassFail: Contract still has provider pToken');
            assert(balancesAfter.marketUsdc.eq(0), 'PassFail: Contract still has reviewer pToken');
        });
    });
});
