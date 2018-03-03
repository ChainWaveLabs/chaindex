let FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
let Exchange = artifacts.require("./Exchange.sol");

contract("Exchange: Deposits and Withdrawals", function (accounts) {
    let fsTokenInstance;
    let exchangeInstance;

    beforeEach('Set up contracts for each test', function () {
        return FixedSupplyToken.deployed().then(function (instance) {
            fsTokenInstance = instance;
            return instance;
        }).then(function (tokenInstance) {
            fsTokenInstance = tokenInstance;
            return Exchange.deployed();
        }).then(function (exInstance) {
            exchangeInstance = exInstance;
        });
    });

    it("Should allow addition of tokens", function () {
        return exchangeInstance.addToken("FIXED", fsTokenInstance.address).then(function () {
            return exchangeInstance.hasToken.call("FIXED");
        }).then(function (boolHasToken) {
            assert.equal(boolHasToken, true, "Token was not added");
            return exchangeInstance.hasToken.call("SDFD#E");
        }).then(function (boolHasToken) {
            assert.equal(boolHasToken, false, "A token that doesn't exist was found")
        });
    });

    it("Should be possible to Deposit and Withdraw Ether", function () {
        let balanceBeforeTx = web3.eth.getBalance(accounts[0]);
        let balanceAfterDeposit;
        let balanceAfterWithdrawal;
        let gasUsed = 0;

        return exchangeInstance.depositEther({
                from: accounts[0],
                value: web3.toWei(1, "ether")
            })
            .then(function (txResult) {
                gasUsed += txResult.receipt.cumulativeGasUsed * web3.eth.getTransaction(txResult.receipt.transactionHash).gasPrice.toNumber();
                balanceAfterDeposit = web3.eth.getBalance(accounts[0]);
                return exchangeInstance.getEthBalanceInWei.call();
            }).then(function (balanceInWei) {
                assert.equal(balanceInWei.toNumber(), web3.toWei(1, "ether"), "There is one ether available");
                assert.isAtLeast(balanceBeforeTx.toNumber() - balanceAfterDeposit.toNumber(), web3.toWei(1, "ether"), "Balance of ");
                exchangeInstance.withdrawEther(web3.toWei(1, "ether"));
            }).then(function (txResult) {
                balanceAfterWithdrawal = web3.eth.getBalance(accounts[0]);
                return exchangeInstance.getEthBalanceInWei.call();
            }).then(function (balanceInWei) {
                assert.equal(balanceInWei.toNumber(), 0, "There is no more ether available");
                assert.isAtLeast(balanceAfterWithdrawal.toNumber(), balanceBeforeTx.toNumber() - gasUsed * 2, "there is one ETH available after withdrawal")
            });
    });

    it("should be possible to deposit a Token", function () {
        return fsTokenInstance.approve(exchangeInstance.address, 2000).then(function (txResult) {
            return exchangeInstance.depositToken("FIXED", 2000)
        }).then(function (depositTxResult) {
            return exchangeInstance.getBalance("FIXED");
        }).then(function (balanceOfToken) {
            assert.equal(balanceOfToken, 2000, "There should be 2000 tokens in the balance");
        });

    });

    it("should be possible to withdraw a Token", function () {
        var balanceTokenInExchangeBeforeWithdrawal;
        var balanceTokenInTokenBeforeWithdrawal;
        var balanceTokenInExchangeAfterWithdrawal;
        var balanceTokenInTokenAfterWithdrawal;

        return exchangeInstance.getBalance("FIXED").then(function(exchangeBalance){
            balanceTokenInExchangeBeforeWithdrawal = exchangeBalance.toNumber();
            return fsTokenInstance.balanceOf.call(accounts[0]);
        }).then(function(tokenBalance){
            balanceTokenInTokenBeforeWithdrawal = tokenBalance.toNumber();
            return exchangeInstance.withdrawToken("FIXED", balanceTokenInExchangeBeforeWithdrawal)
        }).then(function(withdrawTxResult){
            return exchangeInstance.getBalance.call("FIXED")
        }).then(function(exchangeBalanceAfterWithdrawal){
            balanceTokenInExchangeAfterWithdrawal = exchangeBalanceAfterWithdrawal.toNumber();
            return fsTokenInstance.balanceOf.call(accounts[0]);
        }).then(function(tokenBalanceAfterWithdraw){
            balanceTokenInTokenAfterWithdrawal = tokenBalanceAfterWithdraw.toNumber();
            assert.equal(balanceTokenInExchangeAfterWithdrawal, 0, "There should be no tokens left");
            assert.equal(balanceTokenInTokenAfterWithdrawal,  balanceTokenInExchangeBeforeWithdrawal + balanceTokenInTokenBeforeWithdrawal, "The token should have the original exchange balance after withdrawal");
        })

    })

});