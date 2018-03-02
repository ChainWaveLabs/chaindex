var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var FixedSupplyToken = artifacts.require('./FixedSupplyToken.sol');
var owned = artifacts.require('./owned.sol');
var Exchange = artifacts.require('./Exchange.sol');

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.deploy(owned);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(FixedSupplyToken);
  deployer.link(owned, Exchange);
};
