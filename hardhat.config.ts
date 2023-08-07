import 'hardhat-gas-reporter';
import 'hardhat-deploy';
import 'hardhat-watcher';
import 'hardhat-abi-exporter';
import 'hardhat-contract-sizer';
import 'hardhat-docgen';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';
import '@typechain/hardhat';
import 'solidity-coverage';

import { HardhatUserConfig } from 'hardhat/config';
import { task } from 'hardhat/config';

require('dotenv').config();
require('@nomicfoundation/hardhat-chai-matchers');

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;
const ALCHEMY_KEY = process.env.ALCHEMY_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: '0.8.17',
                settings: {
                    optimizer: {
                        enabled: true, 
                        details: {
                            yul: true, 
                            yulDetails: { optimizerSteps: 'u' }
                        }
                    },
                    viaIR: true,
                },
            },
        ],
    },
    gasReporter: {
        currency: 'USD',
        gasPrice: 60,
        coinmarketcap: COINMARKETCAP_API_KEY,
        showMethodSig: true,
        showTimeSpent: true,
    },
    watcher: {
        compilation: {
            tasks: ['compile'],
            files: ['./contracts'],
            verbose: true,
        },
        ci: {
            tasks: [
                'clean',
                { command: 'compile', params: { quiet: true } },
                { command: 'test', params: { noCompile: true, testFiles: ['testfile.ts'] } },
            ],
        },
    },
    abiExporter: [
        {
            path: 'package/abis',
            runOnCompile: true,
            clear: true,
            flat: true,
            spacing: 2,
            format: 'json',
        },
    ],
    contractSizer: {
        alphaSort: false,
        disambiguatePaths: true,
        runOnCompile: false,
    },
    docgen: {
        path: './docs',
        clear: true,
        runOnCompile: true,
    },
    etherscan: {
        apiKey: {
            sepolia: `${ETHERSCAN_API_KEY}`,
            mainnet: `${ETHERSCAN_API_KEY}`,
            polygon: `${POLYGONSCAN_API_KEY}`,
        },
    },
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            chainId: 1337,
            gas: 'auto',
            gasPrice: 'auto',
            saveDeployments: false,
            // mining: {
            //     auto: true,
            // },
        },
        sepolia: {
            url: `https://rpc.sepolia.org/`,
            accounts: [`0x${process.env.PRIVATE_KEY}`],
            gasPrice: 50000000000, // 50 gwei
        },
        mainnet: {
            chainId: 1,
            url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
            accounts: [`0x${process.env.PRIVATE_KEY}`],
            gasPrice: 50000000000, // 50 gwei
        },
        polygon: {
            chainId: 137,
            url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`,
            accounts: [`0x${PRIVATE_KEY}`],
            gasPrice: 150000000000,
        },
    },
    paths: {
        sources: './src', // Use ./src rather than ./contracts as Hardhat expects
        tests: './test/',
    },
    typechain: {
        outDir: 'package/types',
    },
};

export default config;
