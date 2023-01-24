import fs from "fs";
import "hardhat-gas-reporter";
import 'hardhat-deploy';
import "hardhat-watcher";
import "hardhat-abi-exporter";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import "hardhat-preprocessor";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import { HardhatUserConfig } from "hardhat/config";
import { task } from "hardhat/config";

require("dotenv").config();

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
      console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
        {
            version: "0.8.17",
            settings: {
                optimizer: { // Keeps the amount of gas used in check
                    enabled: true,
                    runs: 1000,
                }
            }
        }
    ],
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 60,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    showMethodSig: true,
    showTimeSpent: true,
  },
  watcher: {
    compilation: {
        tasks: ["compile"],
        files: ["./contracts"],
        verbose: true,
    },
    ci: {
        tasks: [
            "clean",
            { command: "compile", params: { quiet: true } },
            { command: "test", params: { noCompile: true, testFiles: ["testfile.ts"] } }
        ],
    }
  },
  abiExporter: {
    path: 'package/abis',
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    format: "json"
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: true,
  },
  etherscan: {
    apiKey: {
        sepolia: `${process.env.ETHERSCAN_API_KEY}`,
        mainnet: `${process.env.ETHERSCAN_API_KEY}`,
        polygon: `${process.env.POLYGONSCAN_API_KEY}`,
    }
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337,
      gas: "auto",
      gasPrice: "auto",
      saveDeployments: false,
      mining: {
          auto: false,
          interval: 1500,
      }
    },
    sepolia: {
      url: `https://rpc.sepolia.org/`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 50000000000, // 50 gwei
    },
    mainnet: {
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 50000000000, // 50 gwei
    },
    polygon: {
      chainId: 137,
      url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.POLYGON_ALCHEMY_KEY}`,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 'auto'
    },
  },
  paths: {
    sources: "./src", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
    tests: "./test/hardhat",
  },
  typechain: {
    outDir: 'package/types'
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          for (const [from, to] of getRemappings()) {
            if (line.includes(from) && !line.includes("openzeppelin")) {
              line = line.replace(from, to);
              break;
            }
          }
        }
        return line;
      },
    }),
  },
};

export default config;