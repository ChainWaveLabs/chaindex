let FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
let Exchange = artifacts.require("./Exchange.sol");

contract("Exchange Basic Tests", function(accounts){
    let fsTokenInstance;
    let exchangeInstance;

    beforeEach('Set up contracts for each test', function () {
        return FixedSupplyToken.deployed().then(function(instance){
            fsTokenInstance = instance;
            return instance;
        }).then(function(tokenInstance){
            fsTokenInstance = tokenInstance;
            return Exchange.deployed();
        }).then(function(exInstance){
            exchangeInstance = exInstance;
        });
    });

    it("Should allow addition of tokens", function(){
        return exchangeInstance.addToken("FIXED", fsTokenInstance.address).then(function(){
            return exchangeInstance.hasToken.call("FIXED");
        }).then(function(boolHasToken){
            assert.equal(boolHasToken, true, "Token was not added");
            return exchangeInstance.hasToken.call("SDFD#E");
        }).then(function(boolHasToken){
            assert.equal(boolHasToken, false, "A token that doesn't exist was found")
        });
    });

});