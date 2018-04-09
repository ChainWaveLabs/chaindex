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
//import { checkServerIdentity } from "tls";

// MetaCoin is our usable abstraction, which we'll use through the code below.

var ChaindexContract = contract(chaindex_artifacts);
var FixedTokenContract = contract(fixed_token_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;


window.App = {

  start: function(){},
  setStatus: function(){},
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
    App.updateTokenBalance();
    App.watchTokenEvents();
    App.broadcastExchangeInfo();
  },
  updateTokenBalance: function(){},
  watchTokenEvents: function(){},
  sendToken: function(){},
  allowanceToken: function(){},
};

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:9545"));
  }

  App.start();
});
