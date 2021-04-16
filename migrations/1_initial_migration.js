const Migrations = artifacts.require("staking");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
