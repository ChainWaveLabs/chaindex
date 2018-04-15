let FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
let Exchange = artifacts.require("./Chaindex.sol");

contract("Order Book Functionality", (accounts) => {
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

    it("should be possible to add one limit buy", () => {
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

    // it("should be possible to add a single sell limit order", () => {
    //     let orderBookLengthBeforeBuy;
    //     return exchangeInstance.getSellOrderBook.call("FIXED")
    //     .then( (sellOrderBook) => {
    //         console.log("sell order book", sellOrderBook);
    //         orderBookLengthBeforeBuy = sellOrderBook.length;
    //         assert.equal(sellOrderBook.length, 2, "Orderbook should have a length of 2");
    //         assert.equal(sellOrderBook[0].length, 0, "Orderbook should have no limit buy orders");
    //         return exchangeInstance.sellToken("FIXED", web3.toWei(1,"finney"), 5)
    //     })
    //    .then((txResult) => {
    //         //look into logs to assert then get orderbook again
    //         assert.equal(txResult.logs.length, 1, "There should be at least one log entry");
    //         assert.equal(txResult.logs[0].event, "LimitSellOrderCreated",  "LimitSellOrderCreated event not fired");
    //         return exchangeInstance.getSellOrderBook.call("FIXED");
    //     }).then((sellOrderBook) => {
    //         console.log("sell order book", sellOrderBook);
    //         assert.equal(sellOrderBook[0].length, orderBookLengthBeforeBuy+1, "Orderbook price  at zero index should have 1 sell offers");
    //         assert.equal(sellOrderBook[1].length, orderBookLengthBeforeBuy+1, "Orderbook volume at zero index should have 1 sell vol instance ");
         
    //     });
    // });

    it("should be possible to add multiple sell limit orders", () => {
        var sellOrderLengthBeforeSell;
        return exchangeInstance.getSellOrderBook.call("FIXED").then((sellOrderBook) =>{
            sellOrderLengthBeforeSell = sellOrderBook[0].length;
            return exchangeInstance.sellToken("FIXED", web3.toWei(3,"finney"), 5);
        }).then((txResult) => {
            assert.equal(txResult.logs.length, 1, "There should have been 1 log message emitted");
            assert.equal(txResult.logs[0].event, "LimitSellOrderCreated",  "LimitSellOrderCreated event not fired");
            return exchangeInstance.sellToken("FIXED", web3.toWei(6, "finney"),5);
        }).then((txResult) => {
            return exchangeInstance.getSellOrderBook.call("FIXED");
        }).then((sellOrderBook) => {
            assert.equal(sellOrderBook[0].length, sellOrderLengthBeforeSell+2, "Orderbook[0] should have 2 sell offers than it started with ")
            assert.equal(sellOrderBook[1].length, sellOrderLengthBeforeSell+2, "Orderbook[1] should have 2 sell volume elements ")
        });
    })

    it("should be able to create and cancel a sell order", () => {
           //1.look into the sell order book at the address of this offer key make sure its msg.sender
            //2. get amt of tokens
            //3. add tokens back to address' balance
            //4. remove from sell book

            let orderBookLengthBeforeSell, orderBookLengthAfterSell, orderBookLengthAfterCancel, orderKey;

            exchangeInstance.getSellOrderBook.call("FIXED").then((sellOrderBook) => {
                orderBookLengthBeforeSell = sellOrderBook[0].length;
                return exchangeInstance.sellToken("FIXED", web3.toWei(2.2, "finney"), 5);
            }).then((txResult) => {
                console.log("Tx result", txResult);
                assert.equal(txResult.logs.length, 1, "Log length should have one Log Message");
                assert.equal(txResult.logs[0].event, "LimitSellOrderCreated", "LimitSellOrderCreated event not fired");
                orderKey = txResult.logs[0].args._orderKey;
                return exchangeInstance.getSellOrderBook.call("FIXED");
            }).then((sellOrderBook) =>{
                orderBookLengthAfterSell = sellOrderBook[0].length;
                assert.equal(orderBookLengthAfterSell,orderBookLengthBeforeSell+ 1, "Sell Orderobok should have one additional order");
                return exchangeInstance.cancelOrder("FIXED",true, web3.toWei(2.2, "finney"),orderKey)
            }).then((txResult) => {
                assert.equal(txResult.logs[0].event, "SellOrderCancelled", "SellOrderCanceled event not fired");
                return exchangeInstance.getSellOrderBook.call("FIXED");
            }).then((sellOrderBook) => {
                orderBookLengthAfterCancel = sellOrderBook[0].length;
                assert.equal(orderBookLengthAfterCancel, orderBookLengthAfterSell, "Sell Orderbook should have removed an order");
                assert.equal(sellOrderBook[1][orderBookLengthAfterCancel-1], 0, "Should have zero available volume.")
            })
    });

    it("should be able to create and cancel a buy order", () => {
          //1.look into the sell order book at the address of this offer key make sure its msg.sender
            //2. get amt ether to refund
            //3. add ether back to original address' balance
            //4. remove from buy book

            let orderBookLengthBeforeBuy, orderBookLengthAfterBuy, orderBookLengthAfterCancel, orderKey;

            exchangeInstance.getBuyOrderBook.call("FIXED").then((buyOrderBook) => {
                orderBookLengthBeforeBuy = buyOrderBook[0].length;
                return exchangeInstance.buyToken("FIXED", web3.toWei(2.2, "finney"), 5);
            }).then((txResult) => {
                console.log("Tx result", txResult);
                assert.equal(txResult.logs.length, 1, "Log length should have one Log Message");
                assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "LimitBuyOrderCreated event not fired");
                orderKey = txResult.logs[0].args._orderKey;
                return exchangeInstance.getBuyOrderBook.call("FIXED");
            }).then((buyOrderBook) =>{
                orderBookLengthAfterBuy = buyOrderBook[0].length;
                assert.equal(orderBookLengthAfterBuy,orderBookLengthBeforeBuy + 1, "Orderobok should have one additional order");
                return exchangeInstance.cancelOrder("FIXED",false, web3.toWei(2.2, "finney"),orderKey)
            }).then((txResult) => {
                assert.equal(txResult.logs[0].event, "BuyOrderCancelled", "BuyOrderCanceled event not fired");
                return exchangeInstance.getBuyOrderBook.call("FIXED");
            }).then((buyOrderBook) => {
                orderBookLengthAfterCancel = buyOrderBook[0].length;
                assert.equal(orderBookLengthAfterCancel, orderBookLengthAfterBuy, "Orderbook should have removed an order");
                assert.equal(buyOrderBook[1][orderBookLengthAfterCancel-1], 0, "Should have zero available volume.")
            })
    });

})