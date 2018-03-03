var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");

contract("FixedSupplyToken", function (accounts) {
    let tokenInstance;

    beforeEach('Set up contract for each test', async function () {
        tokenInstance = await FixedSupplyToken.new();
    });

    it('has an owner', async function () {
        assert.equal(await tokenInstance.owner(), accounts[0])
    });

    it("INIT: should send total supply to the owner (first account)", function () {
        let _totalSupply;

        return tokenInstance.totalSupply.call().then(function(totalSupply){
            _totalSupply = totalSupply;
            return tokenInstance.balanceOf(accounts[0]);
        }).then(function(balanceOfAccountOwner){
            assert.equal(balanceOfAccountOwner.toNumber(), _totalSupply.toNumber(), "Total amt of tokens is owned by owner");
        })
    })

    it("INIT: should have a an account at index 1 with zero tokens", function () {
        return tokenInstance.balanceOf(accounts[1]).then(function(balanceOfAccountOwner){
            assert.equal(balanceOfAccountOwner.toNumber(), 0, "2nd account has zero tokens.");
        });
    })

    it("INIT: should be able to send tokens from one account to another", function () {
        var account_one = accounts[0];
        var account_two = accounts[1];

        var account_one_starting_balance;
        var account_two_starting_balance;
        var account_one_ending_balance;
        var account_two_ending_balance;

        var amount = 10;

        return tokenInstance.balanceOf.call(account_one)
        .then(function (balance) {
            account_one_starting_balance = balance.toNumber();
            return tokenInstance.balanceOf.call(account_two);
        }).then(function (balance) {
            account_two_starting_balance = balance.toNumber();
            return tokenInstance.transfer(account_two, amount, {
                from: account_one
            });
        }).then(function () {
            return tokenInstance.balanceOf.call(account_one);
        }).then(function (balance) {
            account_one_ending_balance = balance.toNumber();
            return tokenInstance.balanceOf.call(account_two);
        }).then(function (balance) {
            account_two_ending_balance = balance.toNumber();

            assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
            assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
        });

    });

});