let FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
let Exchange = artifacts.require("./Exchange.sol");

contract("Exchange: Order Book Functionality", (accounts) => {
    let fsTokenInstance;
    let exchangeInstance;

    before('Set up for test, including depositing ether and tokens in exchange', () => {
        return FixedSupplyToken.deployed().then((instance) => {
                fsTokenInstance = instance;
                return Exchange.deployed();
            }).then((exInstance) => {
                exchangeInstance = exInstance;
                return exchangeInstance.depositEther({
                    from: accounts[0],
                    value: web3.toWei(3, "ether")
                });
            }).then((txResult) => {
                assert.equal(txResult.logs[0].event, "DepositForEthReceived", "DepositForEthReceived event not fired");
                console.log("Exchange Addr:", exchangeInstance.address);
                return exchangeInstance.addToken("FIXED", fsTokenInstance.address);
            }).then((txResult)=>{
                return fsTokenInstance.approve(exchangeInstance.address, 2000);
            })
            .then((txResult) => {
                return exchangeInstance.depositToken("FIXED", 2000);
            });
    });

    it("should be possible to add  one limit buy", () => {
        //from second account, attempt ot purchase the token
        //check balance of tokens on from token contract
        //check balance of tokens in 2nd address
        //check ether balance of 1st address
        return exchangeInstance.getBuyOrderBook.call("FIXED")
        .then( (orderBook) => {
            assert.equal(orderBook.length, 2, "Orderbook should have a length of 2");
            assert.equal(orderBook[0].length, 0, "Orderbook should have no limit buy orders");
            return exchangeInstance.buyToken("FIXED", web3.toWei(1,"finney"), 5);
        }).then((txResult) => {
            //look into logs to assert then get orderbook again
            assert.equal(txResult.logs.length, 1, "There should be at least one log entry");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated",  "LimitBuyOrderCreated event not fired");
            return exchangeInstance.getBuyOrderBook.call("FIXED");
            
        }).then((orderBook) => {
            assert.equal(orderBook[0].length, 1, "Orderbook price  at zero index should have 1 buy offers");
            assert.equal(orderBook[1].length, 1, "Orderbook volume at zero index should have 1 instance ");
         
        });
    });

    it("should be possible to add multiple limit buy orders", () => {
        let orderBookLengthBeforeBuy;
        return exchangeInstance.getBuyOrderBook.call("FIXED")
        .then( (orderBook) => {
            orderBookLengthBeforeBuy = orderBook[0].length;
            return exchangeInstance.buyToken("FIXED", web3.toWei(2,"finney"), 5);
        }).then((txResult) => {
            //look into logs to assert then get orderbook again
            assert.equal(txResult.logs.length, 1, "There should be at least one log entry");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated",  "LimitBuyOrderCreated event not fired");
            return exchangeInstance.buyToken("FIXED", web3.toWei(1.4,"finney"), 5);
            
        }).then((txResult) => {
            assert.equal(txResult.logs.length, 1, "There should be at least one log entry");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated",  "LimitBuyOrderCreated event not fired");
            return exchangeInstance.getBuyOrderBook.call("FIXED")
                     
        }).then((orderBook ) => {
            assert.equal(orderBook[0].length, orderBookLengthBeforeBuy+2, "Orderbook[0] should have 2 more orders than it started with ")
            assert.equal(orderBook[1].length, orderBookLengthBeforeBuy+2, "Orderbook[1] should have 2 more orders than it started with ")
        });
    });

    it("should be possible to add a buy limit order", () => {

    })

    it("should be able to retrieve buy order book", () => {

    });

    it("should be able to retrieve sell order book", () => {

    });




})