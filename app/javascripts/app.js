// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";
import 'bootstrap/dist/css/bootstrap.css';

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'
import 'bootstrap';

// Import our contract artifacts and turn them into usable abstractions.
import chaindex_artifacts from '../../build/contracts/Chaindex.json'
import fixed_token_artifacts from '../../build/contracts/FixedSupplyToken.json'


var ChaindexContract = contract(chaindex_artifacts);
var FixedTokenContract = contract(fixed_token_artifacts);

// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;


window.App = {

  start: function(){
    var self = this;

    // Bootstrap the MetaCoin abstraction for Use.
    ChaindexContract.setProvider(web3.currentProvider);
    FixedTokenContract.setProvider(web3.currentProvider);

    //native web3 call - web3 use error-first functions
    web3.eth.getAccounts(function (err, accs) {
        if (err != null) {
            alert("There was an error fetching your accounts.");
            return;
        }

        if (accs.length == 0) {
            alert("You have zero accounts! Make sure your Ethereum client is configured correctly.");
            return;
        }

        accounts = accs;
        account = accounts[0];
        console.log('Accounts:', accounts);
        console.log('Account[0]:', account);
        App.setStatus('Successfully retrieved Accounts and user account info');

    });
  },

  
  setStatus: function(message){
    var status = document.getElementById("status");
        status.innerHTML = message;
  },
  broadcastExchangeInfo: function(){},
  initChaindex: function(){},
  chaindexEventObserver: function(){},
  addTokenToExchange: function(){},
  refreshBalanceOfExchange: function(){},
  depositEth: function(){},
  withdrawEth: function(){},
  depositToken: function(){},
  withdrawToken: function(){},

  //Trading-specific functionality
  initTrading: function(){
    App.refreshBalanceOfExchange();
    App.broadcastExchangeInfo();
    App.updateOrderBooks();
    App.listenToTradingEvents();
  },
  updateOrderBooks: function(){},
  listenToTradingEvents: function(){},
  sellToken: function(){},
  buyToken: function(){},

  //Token Management/Admin Section
  initTokenManagement: function(){
    console.log('Initialize Token Management');
    App.updateTokenBalance();
    App.watchTokenEvents();
    App.broadcastExchangeInfo();
  },
  updateTokenBalance: function(){
    var tokenInstance;
    console.log('updateTokenBalance');

    FixedTokenContract.deployed().then(function(instance){
      tokenInstance = instance;
      return tokenInstance.balanceOf.call();
    }).then(function(value){
      var balance = document.getElementById("balanceOfTokenInToken");
      console.log('balance', value);
      balance.innerHTML = value.valueOf();
    }).catch(function(e){
      console.log(e);
      App.setStatus('Error getting token balance', e);
    });

  },
  watchTokenEvents: function(){},
  sendToken: function(){},
  allowanceToken: function(){},
};

window.addEventListener('load', function() {
  //whenever we load , we need to find & set the web3provider
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:9545"));
  }

  App.start();
});
