let FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
let Exchange = artifacts.require("./Exchange.sol");

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

    it("should be possible to purchase a Token", () => {
        //approve and deposit token into account
        //in 2nd account, fund contract with ether
        //from second account, attempt ot purchase the token
        //check balance of tokens on from token contract
        //check balance of tokens in 2nd address
        //check ether balance of 1st address
        return fsTokenInstance.approve(exchangeInstance.address, 2000).then((txResult) => {
            return exchangeInstance.depositToken("FIXED", 2000)
        }).then((depositTxResult) => {
            assert.equal(depositTxResult.logs[0].event,"DepositForTokenReceived", "DepositForTokenReceived event not fired");
            return exchangeInstance.getBalance("FIXED");
        }).then((balanceOfToken) => {
            assert.equal(balanceOfToken, 2000, "There should be 2000 tokens in the balance");
            //TODO: 
        });

    });


    it("should be possible to sell a Token", () => {

    });

    it("should be able to retrieve buy order book", () =>{

    });

    it("should be able to retrieve sell order book", () =>{
        
    })


});