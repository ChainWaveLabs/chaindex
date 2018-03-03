var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var FixedSupplyToken = artifacts.require('./FixedSupplyToken.sol');
var Exchange = artifacts.require('./Exchange.sol');

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(FixedSupplyToken);
  deployer.deploy(Exchange);
};
