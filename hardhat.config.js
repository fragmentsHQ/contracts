require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
require("solidity-docgen");
require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-foundry");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_GOERLI_API_URL,
      },
    },
    goerli: {
      chainId: 5,
      url: process.env.ALCHEMY_GOERLI_API_URL,
      accounts: [process.env.FRAGMENTS_KEY],
      saveDeployments: true,
    },
    mumbai: {
      chainId: 80001,
      url: process.env.ALCHEMY_MUMBAI_API_URL,
      accounts: [process.env.FRAGMENTS_KEY],
      saveDeployments: true,
    },
    zkEVM: {
      chainId: 1442,
      url: "https://rpc.public.zkevm-test.net",
      accounts: [process.env.FRAGMENTS_KEY],
      saveDeployments: true,
    },
    gnosis: {
      chainId: 100,
      url: process.env.ALCHEMY_GNOSIS_API_URL,
      accounts: [process.env.FRAGMENTS_KEY],
      saveDeployments: true,
    },
    polygon: {
      chainId: 137,
      url: process.env.ALCHEMY_POLYGON_API_URL,
      accounts: [process.env.FRAGMENTS_KEY],
      saveDeployments: true,
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY,
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
      polygon: process.env.POLYGONSCAN_API_KEY,
    },
  },
  docgen: {},
  gasReporter: {
    enabled: true,
    outputFile: "gas-report.txt",
    currency: "USD",
  },
};
