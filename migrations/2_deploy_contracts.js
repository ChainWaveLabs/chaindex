var FixedSupplyToken = artifacts.require('./FixedSupplyToken.sol');
var Chaindex = artifacts.require('./Chaindex.sol');

var ChainCap = artifacts.require('./ChainCap.sol');

module.exports = function (deployer) {
  deployer.deploy(FixedSupplyToken,{gas: 4500000});
  deployer.deploy(Chaindex,{gas: 5500000});
  deployer.deploy(ChainCap,{gas: 5500000});
};