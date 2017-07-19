var MultisigAdmin = artifacts.require("./MultisigAdmin.sol");
var TimeLockedWallet = artifacts.require("./TimeLockedWallet.sol");

module.exports = function(deployer) {
  deployer.deploy(MultisigAdmin);
  deployer.deploy(TimeLockedWallet);
};
