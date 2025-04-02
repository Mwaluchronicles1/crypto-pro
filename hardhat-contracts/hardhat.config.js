require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");

module.exports = {
  solidity: "0.8.28",  // Update this to match your contract's version
  networks: {
    ganache: {
      url: "http://127.0.0.1:7545",
      accounts: ["0xb4bb9508c8faa1c53a5d8c2a3d0dcaaa1a402100305ce89a88ae82effd86db86"]  // Your Ganache private key
    }
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    gasPrice: 21,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    outputFile: 'gas-report.txt',
    noColors: true,
    excludeContracts: ['Lock'],
  }
};