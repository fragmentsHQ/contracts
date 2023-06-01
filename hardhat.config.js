require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require('solidity-docgen');
// require("@nomiclabs/hardhat-ethers");
// require("@nomiclabs/hardhat-waffle");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.ALCHEMY_GOERLI_API_URL,
        blockNumber: 8685155
      }
    },
    goerli: {
      chainId: 5,
      url: process.env.ALCHEMY_GOERLI_API_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    mumbai: {
      chainId: 80001,
      url: process.env.ALCHEMY_MUMBAI_API_URL,
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 1000000000000
    },
    gnosis: {
      chainId: 100,
      url: process.env.ALCHEMY_GNOSIS_API_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon: {
      chainId: 137,
      url: process.env.ALCHEMY_POLYGON_API_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
    // apiKey: process.env.POLYGONSCAN_API_KEY
  },
  polygonscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY
  },
  docgen: {}
};
