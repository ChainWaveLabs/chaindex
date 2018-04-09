var FixedSupplyToken = artifacts.require('./FixedSupplyToken.sol');
var Chaindex = artifacts.require('./Chaindex.sol');

module.exports = function (deployer) {
  deployer.deploy(FixedSupplyToken);
  deployer.deploy(Chaindex);
};