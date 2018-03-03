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

    it("Should be possible to Deposit and Withdraw Ether", function(){
    let balanceBeforeTx = web3.eth.getBalance(accounts[0]);
    let balanceAfterDeposit;
    let balanceAfterWithdrawal;
    let gasUsed =0;

        return exchangeInstance.depositEther({from:accounts[0], value: web3.toWei(1,"ether")})
        .then(function(txResult){
            gasUsed += txResult.receipt.cumulativeGasUsed * web3.eth.getTransaction(txResult.receipt.transactionHash).gasPrice.toNumber();
            balanceAfterDeposit = web3.eth.getBalance(accounts[0]);
            return exchangeInstance.getEthBalanceInWei.call();
        }).then(function(balanceInWei){
            assert.equal(balanceInWei.toNumber(), web3.toWei(1,"ether"), "There is one ether available");
            assert.isAtLeast(balanceBeforeTx.toNumber() - balanceAfterDeposit.toNumber(), web3.toWei(1,"ether"), "Balance of ");
            exchangeInstance.withdrawEther(web3.toWei(1, "ether"));
        }).then(function(txResult){
            balanceAfterWithdrawal = web3.eth.getBalance(accounts[0]);
            return exchangeInstance.getEthBalanceInWei.call();
        }).then(function(balanceInWei){
            assert.equal(balanceInWei.toNumber(), 0, "There is no more ether available");
            assert.isAtLeast(balanceAfterWithdrawal.toNumber(),balanceBeforeTx.toNumber() - gasUsed * 2, "there is one ETH available after withdrawal")
        })
    })

});