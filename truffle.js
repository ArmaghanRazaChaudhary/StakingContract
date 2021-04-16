const HDWalletProvider = require('truffle-hdwallet-provider');
const mnemonic = "";

module.exports = {
  networks: {
    testnet: {
      provider: () => new HDWalletProvider(mnemonic, `https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.5.3",
      settings: {
        optimizer: {
          enabled: true
        }
      }
    }
  }
}