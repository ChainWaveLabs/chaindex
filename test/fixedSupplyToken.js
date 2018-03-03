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

    it("should have a an account at index 1 with zero tokens", function(){
        var myTokenInstance;

        return FixedSupplyToken.deployed().then(function(instance){
            myTokenInstance = instance;
            return myTokenInstance.balanceOf(accounts[1]);
        }).then(function(balanceOfAccountOwner){
            assert.equal(balanceOfAccountOwner.toNumber(), 0, "2nd account has zero tokens.");
        })
    })

    it("should be able to send tokens from one account to another", function(){
        var myTokenInstance;
        var account_one = accounts[0];
        var account_two = accounts[1];

        var account_one_starting_balance;
        var account_two_starting_balance;
        var account_one_ending_balance;
        var account_two_ending_balance;

        var amount = 10;


        // return FixedSupplyToken.deployed().then(function(instance){
        //     myTokenInstance = instance;
        //     return myTokenInstance.balanceOf(accounts[1]);
        // }).then(function(balanceOfAccountOwner){
        //     assert.equal(balanceOfAccountOwner.toNumber(), 0, "2nd account has zero tokens.");
        // })

        return FixedSupplyToken.deployed().then(function(instance) {
            myTokenInstance = instance;
            return myTokenInstance.balanceOf.call(account_one);
          }).then(function(balance) {
            account_one_starting_balance = balance.toNumber();
            return myTokenInstance.balanceOf.call(account_two);
          }).then(function(balance) {
            account_two_starting_balance = balance.toNumber();
            return myTokenInstance.transfer(account_two, amount, {from: account_one});
          }).then(function() {
            return myTokenInstance.balanceOf.call(account_one);
          }).then(function(balance) {
            account_one_ending_balance = balance.toNumber();
            return myTokenInstance.balanceOf.call(account_two);
          }).then(function(balance) {
            account_two_ending_balance = balance.toNumber();
      
            assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
            assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
          });

    });
    
});