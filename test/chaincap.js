const ChainCap = artifacts.require("./ChainCap.sol");
contract('ChainCap', (accounts) => {
    let chainCap;
    let owner = accounts[0];
    let donor = accounts[1];

    beforeEach('set up contract for each test', async () => {
        chainCap = await ChainCap.new();
    });


    describe('Admin / Owner Functionality', async () => {
        it('has an owner', async () => {
            assert.equal(await chainCap.getOwner(), owner)
        })

        it('is able to accept funds', async () => {
            await chainCap.sendTransaction({
                value: 1e+18,
                from: donor
            })
            const chainCapAddress = await chainCap.address
            assert.equal(web3.eth.getBalance(chainCapAddress).toNumber(), 1e+18)
        })

        it('should be able to pause new transaction activity', async () => {
            const chainCapAddress = await chainCap.address;
            const startingBalance = web3.eth.getBalance(chainCapAddress).toNumber();
            await chainCap.pause()

            try {
                await chainCap.sendTransaction({
                    value: 1e+18,
                    from: donor
                })
                //supposed to fail while paused
                assert.fail();
            } catch (error) {
                assert(error.toString().includes('VM Exception'), error.toString())
            }
        })

        it('should be able to resume transaction activity after pausing then unpausing', async () => {
            const chainCapAddress = await chainCap.address

            await chainCap.pause();

            await chainCap.unpause()

            await chainCap.sendTransaction({
                value: 1e+18,
                from: donor
            })

            assert.equal(web3.eth.getBalance(chainCapAddress).toNumber(), 1e+18, "New balance is not correct");
        })

        it('should allow owner to add a assets to the contract', async () => {
            await chainCap.addAsset("ETH");
            await chainCap.addAsset("BTC");
            await chainCap.addAsset("LTC");
            const assets = await chainCap.getNumberAssets();
            assert.equal(assets.toNumber(), 3);
        });

        it('should not allow owner to add duplicate assets to the contract', async () => {
            await chainCap.addAsset("ETH");
            
            try {
                await chainCap.addAsset("ETH");
            } catch (error) {
                assert(error.toString().includes('revert'), error.toString())
            }
        });

        it('should enable admin/owner to update the subscription price and duration', async ()=> {

        })

    });


    describe('Subscribing to Assets', async () => {
       

        it('should allow a user to subscribe to an asset', async () => {
            await chainCap.subscribeTo("ETH");


        });

        it('should allow a user to subscribe to many assets', async () => {

        });

        it('should not allow user to subscribe to an asset they are already subscribed to', async () => {

        });

        it('should update the last subscription block for an asset when a new subscription is made', async () => {

        });



    });

    describe('Subscription Duration limiting', async () => {
        it('should limit the duration of a subscription to approximately 7 days', async () => {
            //remove subscription from subscriptions
        });


    
    });

    describe('Safe Delisting of Assets', async () => {

        it('should allow owner to remove an asset from the contract', async () => {

        })

        it('should not remove an asset with active subscription until last subscription expires', async ()=>{ 

        });

        it('should not allow new subscriptions to be initiate after the owner initiates removal of the contract', async () => {

        })
    });



   



});


/*
ASYNC

beforeEach(async function() {
  await db.clear();
  await db.save([tobi, loki, jane]);
});

describe('#find()', function() {
  it('responds with matching records', async function() {
    const users = await db.find({ type: 'User' });
    users.should.have.length(3);
  });
});

//SYNCRHONOUS

describe('Array', function() {
  describe('#indexOf()', function() {
    it('should return -1 when the value is not present', function() {
      [1,2,3].indexOf(5).should.equal(-1);
      [1,2,3].indexOf(0).should.equal(-1);
    });
  });
});

//ARROWZS

describe('my suite', () => {
  it('my test', () => {
    // should set the timeout of this test to 1000 ms; instead will fail
    this.timeout(1000);
    assert.ok(true);
  });
});




console.log('Starting Execution');

const promise = rp('http://example.com/');
promise.then(result => console.log(result));

console.log("Can't know if promise has finished yet...");


*/