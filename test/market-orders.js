let FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
let Exchange = artifacts.require("./Exchange.sol");

contract("Exchange: Market Orders", (accounts) => {
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
            }).then((txResults) => {
                return fsTokenInstance.transfer(accounts[1],2000);
            }).then((txResult) => {
                return fsTokenInstance.approve(exchangeInstance.address, 2000);
            })
            .then((txResult) => {
                return exchangeInstance.depositToken("FIXED", 2000);
            });
    });


    it("should be able to make a market sell order", ()=> {
        return false;

        // return exchangeInstance.getBuyOrderBook.call("FIXED")
        // .then( (orderBook) => {
        //     assert.equal(orderBook.length, 2, "Orderbook should have a length of 2");
        //     assert.equal(orderBook[0].length, 0, "Orderbook should have no limit buy orders");
        //     return exchangeInstance.buyToken("FIXED", web3.toWei(1,"finney"), 5);
        // }).then((txResult) => {
        //     //look into logs to assert then get orderbook again
        //     assert.equal(txResult.logs.length, 1, "There should be at least one log entry");
        //     assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated",  "LimitBuyOrderCreated event not fired");
        //     return exchangeInstance.getBuyOrderBook.call("FIXED");
            
        // }).then((orderBook) => {
        //     assert.equal(orderBook[0].length, 1, "Orderbook price  at zero index should have 1 buy offers");
        //     assert.equal(orderBook[1].length, 1, "Orderbook volume at zero index should have 1 instance ");
         
        // });
    });

    it("should be able to make and fulfill a market buy order", ()=> {

        //get baseline
        //buy token
        //assert logs
        //sell token
        //assert logs
        //get both buy and sell orderbook and assert lengths of both
       return exchangeInstance.getBuyOrderBook.call("FIXED").then((buyOrderBook) => {
            assert.equal(buyOrderBook.length, 2, "Buy Order Book should have 2 elements");
            assert.equal(buyOrderBook[0].length, 0, "Buy Order Book should 0 offers to buy");
            return exchangeInstance.buyToken("FIXED", web3.toWei(3, "finney"), 5);
        }).then( (txResult) => {
            assert.equal(txResult.logs.length, 1, "Log length should have one Log Message");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "LimitBuyOrderCreated event not fired");
           
            return exchangeInstance.getBuyOrderBook.call("FIXED");
        }).then((buyOrderBook) => { 
            assert.equal(buyOrderBook[0].length, 1, "Buy Order Book should have 1 buy offer");
            assert.equal(buyOrderBook[1].length, 1, "Buy Order Book should have 1 buy voluem elem");
            assert.equal(buyOrderBook[1][0], 1, "Should have vol of 5 coins that someone wants to buy");
            exchangeInstance.sellToken("FIXED", web3.toWei(3, "finney"), 5, {from: accounts[1]});
        }).then((txResult) => {
            assert.equal(txResult.logs.length, 1, "Log length should have one Log Message");
            assert.equal(txResult.logs[0].event, "SellOrderFulfilled", "SellOrderFulfilled event not fired");
            return exchangeInstance.getBuyOrderBook.call("FIXED")
        }).then((buyOrderBook) => {
            
        })
    });


});