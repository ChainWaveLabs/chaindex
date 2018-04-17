var FixedSupplyToken = artifacts.require('./FixedSupplyToken.sol');
var Chaindex = artifacts.require('./Chaindex.sol');

module.exports = function (deployer) {
  deployer.deploy(FixedSupplyToken,{gas: 4500000});
  deployer.deploy(Chaindex,{gas: 5500000});
};