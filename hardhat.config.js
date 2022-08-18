require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.13",
  networks: {
    binance_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon_testnet: {
      url: "https://matic-mumbai.chainstacklabs.com",
      accounts: [process.env.PRIVATE_KEY]
    },
    ethereum_testnet: {
      url: "https://rpc.ankr.com/eth_ropsten",
      accounts: [process.env.PRIVATE_KEY]
    },
    avalanche_testnet: {
      url: "https://rpc.ankr.com/avalanche_fuji",
      accounts: [process.env.PRIVATE_KEY]
    },
    avalanche_mainnet: {
      url: "https://ava-mainnet.public.blastapi.io/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
    binance_mainnet: {
      url: "https://bsc-mainnet.nodereal.io/v1/64a9df0874fb4a93b9d0a3849de012d3",
      accounts: [process.env.PRIVATE_KEY]
    },
    ethereum_mainnet: {
      url: "https://eth-mainnet.nodereal.io/v1/1659dfb40aa24bbb8153a677b98064d7",
      accounts: [process.env.PRIVATE_KEY],
      blockGasLimit: 74000
    },
    polygon_mainnet: {
      url: "https://matic-mainnet.chainstacklabs.com",
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSCSCAN_API_KEY,
      bsc: process.env.BSCSCAN_API_KEY,
      polygon: process.env.POLYGON_API_KEY,
      avalanche: process.env.AVALANCHE_API_KEY,
      mainnet: process.env.ETHEREUM_API_KEY
    }
  }
};
