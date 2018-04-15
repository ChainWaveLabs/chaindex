let FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
let Exchange = artifacts.require("./Chaindex.sol");

contract("Exchange: Deposits and Withdrawals", (accounts) => {
    let fsTokenInstance;
    let exchangeInstance;

    beforeEach('Set up contracts for each test', () => {
        return FixedSupplyToken.deployed().then( (instance) =>  {
            fsTokenInstance = instance;
            return instance;
        }).then( (tokenInstance) => {
            fsTokenInstance = tokenInstance;
            return Exchange.deployed();
        }).then( (exInstance) => {
            exchangeInstance = exInstance;
        });
    });

    it("Should allow addition of tokens", () => {
        return exchangeInstance.addToken("FIXED", fsTokenInstance.address).then( (txResult) => {
            assert.equal(txResult.logs[0].event,"TokenAddedToSystem", "TokenAddedToSystem event not fired");
            return exchangeInstance.hasToken.call("FIXED");
        }).then( (boolHasToken) => {
            assert.equal(boolHasToken, true, "Token was not added");
            return exchangeInstance.hasToken.call("SDFD#E");
        }).then( (boolHasToken) => {
            assert.equal(boolHasToken, false, "A token that doesn't exist was found")
        });
    });

    it("Should be possible to Deposit and Withdraw Ether", () => {
        let balanceBeforeTx = web3.eth.getBalance(accounts[0]);
        let balanceAfterDeposit;
        let balanceAfterWithdrawal;
        let gasUsed = 0;

        return exchangeInstance.depositEther({
                from: accounts[0],
                value: web3.toWei(1, "ether")
            })
            .then((txResult) => {
                assert.equal(txResult.logs[0].event,"DepositForEthReceived", "DepositForEthReceived event not fired");
                gasUsed += txResult.receipt.cumulativeGasUsed * web3.eth.getTransaction(txResult.receipt.transactionHash).gasPrice.toNumber();
                balanceAfterDeposit = web3.eth.getBalance(accounts[0]);
                return exchangeInstance.getEthBalanceInWei.call();
            }).then((balanceInWei)=> {
                assert.equal(balanceInWei.toNumber(), web3.toWei(1, "ether"), "There is one ether available");
                assert.isAtLeast(balanceBeforeTx.toNumber() - balanceAfterDeposit.toNumber(), web3.toWei(1, "ether"), "Balance of ");
                return exchangeInstance.withdrawEther(web3.toWei(1, "ether"));
            }).then((txResult) => {
                assert.equal(txResult.logs[0].event,"WithdrawEth", "WithdrawEth event not fired");
                balanceAfterWithdrawal = web3.eth.getBalance(accounts[0]);
                return exchangeInstance.getEthBalanceInWei.call();
            }).then((balanceInWei) => {
                assert.equal(balanceInWei.toNumber(), 0, "There is no more ether available");
                assert.isAtLeast(balanceAfterWithdrawal.toNumber(), balanceBeforeTx.toNumber() - gasUsed*2, "There is one ether available");
             });
    });

    it("should be possible to deposit a Token", () => {
        return fsTokenInstance.approve(exchangeInstance.address, 2000).then((txResult) => {
            return exchangeInstance.depositToken("FIXED", 2000)
        }).then((depositTxResult) => {
            assert.equal(depositTxResult.logs[0].event,"DepositForTokenReceived", "DepositForTokenReceived event not fired");
            return exchangeInstance.getBalance("FIXED");
        }).then((balanceOfToken) => {
            assert.equal(balanceOfToken, 2000, "There should be 2000 tokens in the balance");
        });

    });

    it("should be possible to withdraw a Token", () => {
        var balanceTokenInExchangeBeforeWithdrawal;
        var balanceTokenInTokenBeforeWithdrawal;
        var balanceTokenInExchangeAfterWithdrawal;
        var balanceTokenInTokenAfterWithdrawal;

        return exchangeInstance.getBalance("FIXED").then((exchangeBalance) => {
            balanceTokenInExchangeBeforeWithdrawal = exchangeBalance.toNumber();
            return fsTokenInstance.balanceOf.call(accounts[0]);
        }).then((tokenBalance) => {
            balanceTokenInTokenBeforeWithdrawal = tokenBalance.toNumber();
            return exchangeInstance.withdrawToken("FIXED", balanceTokenInExchangeBeforeWithdrawal)
        }).then((withdrawTxResult) => {
            assert.equal(withdrawTxResult.logs[0].event,"WithdrawToken", "WithdrawToken event not fired");
            return exchangeInstance.getBalance.call("FIXED")
        }).then((exchangeBalanceAfterWithdrawal) => {
            balanceTokenInExchangeAfterWithdrawal = exchangeBalanceAfterWithdrawal.toNumber();
            return fsTokenInstance.balanceOf.call(accounts[0]);
        }).then((tokenBalanceAfterWithdraw) => {
            balanceTokenInTokenAfterWithdrawal = tokenBalanceAfterWithdraw.toNumber();
            assert.equal(balanceTokenInExchangeAfterWithdrawal, 0, "There should be no tokens left");
            assert.equal(balanceTokenInTokenAfterWithdrawal,  balanceTokenInExchangeBeforeWithdrawal + balanceTokenInTokenBeforeWithdrawal, "The token should have the original exchange balance after withdrawal");
        })

    })

});