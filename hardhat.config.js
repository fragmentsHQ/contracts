require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
require("solidity-docgen");
require("@nomicfoundation/hardhat-foundry");
// require("@nomiclabs/hardhat-ethers");
// require("@nomiclabs/hardhat-waffle");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
      outputSelection: {
        '*': {
          '*': ['storageLayout'],
        },
      }
    },
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_MUMBAI_API_URL,
      },
    },
    goerli: {
      chainId: 5,
      url: process.env.ALCHEMY_GOERLI_API_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
    mumbai: {
      chainId: 80001,
      url: process.env.ALCHEMY_MUMBAI_API_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
    zkEVM: {
      chainId: 1442,
      url: "https://rpc.public.zkevm-test.net",
      accounts: [process.env.PRIVATE_KEY],
    },
    // gnosis: {
    //   chainId: 100,
    //   url: process.env.ALCHEMY_GNOSIS_API_URL,
    //   accounts: [process.env.PRIVATE_KEY]
    // },
    // polygon: {
    //   chainId: 137,
    //   url: process.env.ALCHEMY_POLYGON_API_URL,
    //   accounts: [process.env.PRIVATE_KEY]
    // },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY,
      polygonMumbai: process.env.POLYGONSCAN_API_KEY,
    },
  },
  docgen: {},
};
