var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");

contract("MyToken", function(accounts){

    it("should send total supply to the owner (first account)",  function(){
        var _totalSupply;
        var myTokenInstance;

        return FixedSupplyToken.deployed().then(function(instance){
            myTokenInstance = instance;
            return myTokenInstance.totalSupply.call(); //call constant functions
        }).then(function(totalSupply){
            _totalSupply = totalSupply;
            return myTokenInstance.balanceOf(accounts[0]);
        }).then(function(balanceOfAccountOwner){
            assert.equal(balanceOfAccountOwner.toNumber(),_totalSupply.toNumber(), "Total amt of tokens is owned by owner");
        })
    });
    
})