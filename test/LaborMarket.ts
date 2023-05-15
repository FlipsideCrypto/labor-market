const hre = require('hardhat');
const { assert, expect } = require('chai');
const { loadFixture, mine } = require('@nomicfoundation/hardhat-network-helpers');

require('chai').use(require('chai-as-promised')).should();

const ethers = hre.ethers;

import type { LaborMarketInterface } from '../package/types/src/LaborMarket';

async function getCurrentBlockTimestamp() {
    return hre.ethers.provider.getBlock('latest').then((block: any) => block.timestamp);
}

describe('Labor Market', function () {
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

        const EnforcementCriteria = await ethers.getContractFactory('BucketEnforcement');
        const enforcement = await EnforcementCriteria.deploy();
        await enforcement.deployed();

        return { factory, enforcement, laborMarketSingleton, ERC20s };
    }

    async function createMarket() {
        const { factory, enforcement, ERC20s } = await loadFixture(deployFactory);
        const [deployer] = await ethers.getSigners();

        const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
        const sigs: any = [];
        const nodes: any = [];

        const maxScore = [100];
        const scoreRanges = [0, 25, 50, 70, 90];
        const scoreWeights = [0, 25, 50, 75, 100];

        const args = [
            deployer.address, // address _deployer,
            criteria, // EnforcementCriteriaInterface _criteria,
            maxScore, // uint256[] memory _auxilaries,
            scoreRanges, // uint256[] memory _alphas,
            scoreWeights, // uint256[] memory _betas
            sigs, // bytes4[] memory _sigs,
            nodes, // Node[] memory _nodes,
        ];

        const tx = await factory.createLaborMarket(...args);
        const receipt = await tx.wait();

        const event = receipt.events.find((e: any) => e.event === 'LaborMarketCreated');

        const marketAddress = event.args.marketAddress;

        const market = await ethers.getContractAt('LaborMarket', marketAddress);

        const [pepeApproval, usdcApproval, wethApproval, nearApproval] = await Promise.all([
            ERC20s.pepe.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
            ERC20s.usdc.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
            ERC20s.weth.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
            ERC20s.near.connect(deployer).approve(market.address, ethers.utils.parseEther('10000000000')),
        ]);

        await Promise.all([pepeApproval.wait(), usdcApproval.wait(), wethApproval.wait(), nearApproval.wait()]);

        return { market, factory, enforcement, deployer, ERC20s };
    }

    async function createMarketWithRequest() {
        const { market, deployer, ERC20s } = await loadFixture(createMarket);

        const now = await getCurrentBlockTimestamp();

        const request: LaborMarketInterface.ServiceRequestStruct = {
            signalExp: now + 1000, // uint48
            submissionExp: now + 2000, // uint48
            enforcementExp: now + 3000, // uint48
            providerLimit: 100, // uint64
            reviewerLimit: 100, // uint64
            pTokenProviderTotal: ethers.utils.parseEther('100'), // uint256
            pTokenReviewerTotal: ethers.utils.parseEther('100'), // uint256
            pTokenProvider: ERC20s.pepe.address, // IERC20
            pTokenReviewer: ERC20s.usdc.address, // IERC20
        };

        const tx = await market.submitRequest(0, request, 'insertURIhere');
        const receipt = await tx.wait();

        const requestId = receipt.events.find((e: any) => e.event === 'RequestConfigured').args.requestId;

        return { market, requestId, ERC20s, deployer };
    }

    async function createMarketWithSubmission() {
        let { market, requestId, ERC20s } = await loadFixture(createMarketWithRequest);

        const [, provider] = await ethers.getSigners();

        market = market.connect(provider);

        const signal = await market.signal(requestId);
        await signal.wait();

        const submissionId = await market.callStatic.provide(requestId, 'uri');

        const provide = await market.provide(requestId, 'uri');
        await provide.wait();

        return { market, requestId, submissionId, ERC20s };
    }

    describe('LaborMarketFactory.sol', async () => {
        it('call: createLaborMarket()', async () => {
            const { factory, enforcement, laborMarketSingleton } = await loadFixture(deployFactory);
            const [deployer] = await ethers.getSigners();

            const criteria = enforcement.address; // EnforcementCriteriaInterface _criteria,
            const auxilaries = [4];
            const alphas = [0, 1, 2, 3, 4];
            const betas = [0, 0, 100, 200, 300];
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

            const contractAddress = await factory.callStatic.createLaborMarket(...args);

            await expect(factory.createLaborMarket(...args))
                .to.emit(factory, 'LaborMarketCreated')
                .withArgs(contractAddress, deployer.address, laborMarketSingleton.address);
        });
    });

    describe('LaborMarket.sol', async () => {
        it('call: submitRequest()', async () => {
            const { market, ERC20s } = await loadFixture(createMarket);

            const [deployer] = await ethers.getSigners();

            const now = await getCurrentBlockTimestamp();

            const [usdcBalanceBefore, pepeBalanceBefore] = await Promise.all([
                ERC20s.usdc.balanceOf(deployer.address),
                ERC20s.pepe.balanceOf(deployer.address),
            ]);

            const request: LaborMarketInterface.ServiceRequestStruct = {
                signalExp: now + 10000, // uint48
                submissionExp: now + 20000, // uint48
                enforcementExp: now + 30000, // uint48
                providerLimit: 100, // uint64
                reviewerLimit: 100, // uint64
                pTokenProviderTotal: ethers.utils.parseEther('100'), // uint256
                pTokenReviewerTotal: ethers.utils.parseEther('1'), // uint256
                pTokenProvider: ERC20s.pepe.address, // IERC20
                pTokenReviewer: ERC20s.usdc.address, // IERC20
            };

            expect(await market.connect(deployer).submitRequest(0, request, 'insertURIhere')).to.emit(
                market,
                'RequestConfigured',
            );

            const [usdcBalanceAfter, pepeBalanceAfter] = await Promise.all([
                ERC20s.usdc.balanceOf(deployer.address),
                ERC20s.pepe.balanceOf(deployer.address),
            ]);

            expect(pepeBalanceAfter).to.eq(pepeBalanceBefore.sub(request.pTokenProviderTotal));
            expect(usdcBalanceAfter).to.eq(usdcBalanceBefore.sub(request.pTokenReviewerTotal));
        });

        it('call: signal()', async () => {
            const { market, requestId } = await loadFixture(createMarketWithRequest);

            const [, provider] = await ethers.getSigners();

            await expect(market.connect(provider).signal(requestId))
                .to.emit(market, 'RequestSignal')
                .withArgs(provider.address, requestId);
        });

        it('call: provide()', async () => {
            let { market, requestId } = await loadFixture(createMarketWithRequest);

            const provider = (await ethers.getSigners())[1];

            market = market.connect(provider);

            const signal = await market.signal(requestId);
            await signal.wait();

            const submissionId = await market.callStatic.provide(requestId, 'uri');

            await expect(market.provide(requestId, 'uri'))
                .to.emit(market, 'RequestFulfilled')
                .withArgs(provider.address, requestId, submissionId, 'uri');
        });

        it('call: signalReview()', async () => {
            const { market, requestId } = await loadFixture(createMarketWithRequest);
            const reviewer = (await ethers.getSigners())[2];

            expect(await market.connect(reviewer).signalReview(requestId, 10))
                .to.emit('ReviewSignal')
                .withArgs(reviewer.address, requestId, 10);
        });

        it('call: review()', async () => {
            let { market, requestId, submissionId, ERC20s } = await loadFixture(createMarketWithSubmission);

            const reviewer = (await ethers.getSigners())[2];

            const signal = await market.connect(reviewer).signalReview(requestId, 10);
            await signal.wait();

            expect(await market.connect(reviewer).review(requestId, submissionId, 100, 'review'))
                .to.emit(market, 'RequestReviewed')
                .withArgs(reviewer.address, requestId, submissionId, 100, 'review');
        });
        it('call: claim()', async () => {
            let { market, requestId, submissionId, ERC20s } = await loadFixture(createMarketWithSubmission);

            const provider = (await ethers.getSigners())[1];
            const reviewer = (await ethers.getSigners())[2];

            const [providerPepeBalanceBefore, reviewerUsdcBalanceBefore, marketUsdcBefore, marketPepeBefore] =
                await Promise.all([
                    ERC20s.pepe.balanceOf(provider.address),
                    ERC20s.usdc.balanceOf(reviewer.address),
                    ERC20s.usdc.balanceOf(market.address),
                    ERC20s.pepe.balanceOf(market.address),
                ]);

            const signal = await market.connect(reviewer).signalReview(requestId, 10);
            await signal.wait();

            const review = await market.connect(reviewer).review(requestId, submissionId, 100, 'review');
            await review.wait();

            await mine(10000);

            const claim = await market.connect(provider).claim(requestId, submissionId);
            await claim.wait();

            const [providerPepeBalanceAfter, reviewerUsdcBalanceAfter, marketUsdcAfter, marketPepeAfter] =
                await Promise.all([
                    ERC20s.pepe.balanceOf(provider.address),
                    ERC20s.usdc.balanceOf(reviewer.address),
                    ERC20s.usdc.balanceOf(market.address),
                    ERC20s.pepe.balanceOf(market.address),
                ]);

            expect(providerPepeBalanceAfter).to.eq(providerPepeBalanceBefore.add(ethers.utils.parseEther('1')));
            expect(reviewerUsdcBalanceAfter).to.eq(reviewerUsdcBalanceBefore.add(ethers.utils.parseEther('1')));
            expect(marketUsdcAfter).to.eq(marketUsdcBefore.sub(ethers.utils.parseEther('1')));
            expect(marketPepeAfter).to.eq(marketPepeBefore.sub(ethers.utils.parseEther('1')));
        });
        it('call: claim() - multiple provider', async () => {
            const { market, requestId, submissionId, ERC20s } = await loadFixture(createMarketWithSubmission);

            const providers = (await ethers.getSigners()).slice(10, 14);

            const signals = await Promise.all(
                providers.map((provider: any) => market.connect(provider).signal(requestId)),
            );
            await Promise.all(signals.map((signal) => signal.wait()));

            const submissionCalls = await Promise.all(
                providers.map((provider: any) => market.connect(provider).provide(requestId, 'uri')),
            );
            const submissionReceipts = await Promise.all(submissionCalls.map((submission) => submission.wait()));

            const submissions = [
                ...submissionReceipts.map((receipt, idx: number) => {
                    const event = receipt.events?.find((event: any) => event.event === 'RequestFulfilled');
                    return {
                        provider: providers[idx],
                        fulfiller: event.args.fulfiller,
                        submissionId: event.args.submissionId,
                        score: (idx + 1) * 25,
                    };
                }),
            ];

            // Handle reviews
            const reviewer = (await ethers.getSigners())[2];

            const signalReview = await market.connect(reviewer).signalReview(requestId, 10);
            await signalReview.wait();

            const reviews = await Promise.all(
                submissions.map((submission, idx: number) =>
                    market.connect(reviewer).review(requestId, submission.submissionId, submission.score, 'review'),
                ),
            );
            await Promise.all(reviews.map((review) => review.wait()));

            await mine(10000);

            for (let idx = 0; idx < submissions.length; idx++) {
                await expect(market.connect(providers[idx]).claim(requestId, submissions[idx].submissionId))
                    .to.emit(market, 'RequestPayClaimed')
                    .withArgs(
                        providers[idx].address,
                        requestId,
                        submissions[idx].submissionId,
                        ethers.utils.parseEther(((idx + 1) * 0.25).toString()),
                        providers[idx].address,
                    );
            }
        });
        it('call: claimRemainder()', async () => {
            let { market, requestId, submissionId, ERC20s } = await loadFixture(createMarketWithSubmission);

            const [requester, provider, reviewer] = await ethers.getSigners();

            const [requesterPepeBalanceBefore, requesterUsdcBalanceBefore] = await Promise.all([
                ERC20s.pepe.balanceOf(requester.address),
                ERC20s.usdc.balanceOf(requester.address),
            ]);

            const signal = await market.connect(reviewer).signalReview(requestId, 10);
            await signal.wait();

            const review = await market.connect(reviewer).review(requestId, submissionId, 100, 'review');
            await review.wait();

            await mine(10000);

            const claim = await market.connect(provider).claim(requestId, submissionId);
            await claim.wait();

            const claimRemainder = await market.connect(requester).claimRemainder(requestId);
            await claimRemainder.wait();

            const [requesterPepeBalanceAfter, requesterUsdcBalanceAfter, marketUsdcAfter, marketPepeAfter] =
                await Promise.all([
                    ERC20s.pepe.balanceOf(requester.address),
                    ERC20s.usdc.balanceOf(requester.address),
                    ERC20s.usdc.balanceOf(market.address),
                    ERC20s.pepe.balanceOf(market.address),
                ]);

            // console.log('net change', requesterPepeBalanceBefore, requesterPepeBalanceAfter);
            // console.log('reviewer payment', requesterUsdcBalanceBefore, requesterUsdcBalanceAfter);

            expect(marketUsdcAfter).to.eq(ethers.utils.parseEther('0'));
            expect(marketPepeAfter).to.eq(ethers.utils.parseEther('0'));
            expect(requesterPepeBalanceAfter).to.eq(requesterPepeBalanceBefore.add(ethers.utils.parseEther('99')));
            expect(requesterUsdcBalanceAfter).to.eq(requesterUsdcBalanceBefore.add(ethers.utils.parseEther('99')));
        });
        it('call: withdrawRequest()', async () => {
            let { market, requestId, ERC20s } = await loadFixture(createMarketWithRequest);

            const [requester] = await ethers.getSigners();

            const [requesterPepeBalanceBefore, requesterUsdcBalanceBefore] = await Promise.all([
                ERC20s.pepe.balanceOf(requester.address),
                ERC20s.usdc.balanceOf(requester.address),
            ]);

            const withdrawRequest = await market.connect(requester).withdrawRequest(requestId);
            await withdrawRequest.wait();

            const [requesterPepeBalanceAfter, requesterUsdcBalanceAfter, marketUsdcAfter, marketPepeAfter] =
                await Promise.all([
                    ERC20s.pepe.balanceOf(requester.address),
                    ERC20s.usdc.balanceOf(requester.address),
                    ERC20s.usdc.balanceOf(market.address),
                    ERC20s.pepe.balanceOf(market.address),
                ]);

            expect(marketUsdcAfter).to.eq(ethers.utils.parseEther('0'));
            expect(marketPepeAfter).to.eq(ethers.utils.parseEther('0'));
            expect(requesterPepeBalanceAfter).to.eq(requesterPepeBalanceBefore.add(ethers.utils.parseEther('100')));
            expect(requesterUsdcBalanceAfter).to.eq(requesterUsdcBalanceBefore.add(ethers.utils.parseEther('100')));
        });
        it('fail: withdrawRequest() - already active', async () => {
            let { market, requestId } = await loadFixture(createMarketWithRequest);

            const [requester, provider] = await ethers.getSigners();

            const signal = await market.connect(provider).signal(requestId);
            await signal.wait();

            await expect(market.connect(requester).withdrawRequest(requestId)).to.be.revertedWith(
                'LaborMarket::withdrawRequest: Already active',
            );
        });
    });
});
