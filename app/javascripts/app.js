// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";
import 'bootstrap/dist/css/bootstrap.css';

// Import libraries we need.
import {
  default as Web3
} from 'web3';
import {
  default as contract
} from 'truffle-contract'
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

  start: function () {
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


  setStatus: function (message) {
    var status = document.getElementById("status");
    status.innerText = message;
  },
  
  initChaindex: function () {
    App.refreshBalanceOfExchange();
    App.broadcastExchangeInfo();
    App.chaindexEventObserver();

  },
  chaindexEventObserver: function () {},

  broadcastExchangeInfo: function () {
    console.log("Broadcast exchange info")
    //Information on the exchange include contract address, token contract address, and account balances
    //contract information
    ChaindexContract.deployed().then(function(instance){
      console.log(instance.address);
      var divContractAddress = document.createElement("div");
      divContractAddress.appendChild(document.createTextNode("Chaindex Contract:" + instance.address));
      divContractAddress.setAttribute("class", "alert alert-info");
      document.getElementById("importantInformation").appendChild(divContractAddress);
    });

    //token information
    FixedTokenContract.deployed().then(function(instance){
      console.log(instance.address);
      var divTokenAddress = document.createElement("div");
      divTokenAddress.appendChild(document.createTextNode("Token Contract:" + instance.address));
      divTokenAddress.setAttribute("class", "alert alert-info");
      document.getElementById("importantInformation").appendChild(divTokenAddress);
    })

    //account address & balance
    web3.eth.getAccounts(function(err,ethAccounts){
      web3.eth.getBalance(ethAccounts[0], function(err1, balance){
        console.log(ethAccounts[0]);
        console.log(web3.fromWei(balance,"ether"));
        var divAccounts = document.createElement("div");
        var div = document.createElement("div");
        div.appendChild(document.createTextNode("Main Account:"+ethAccounts[0]));
        var div2 = document.createElement("div");
        div2.appendChild(document.createTextNode("Eth Balance:"+ web3.fromWei(balance,"ether")));
        divAccounts.appendChild(div);
        divAccounts.appendChild(div2);
        divAccounts.setAttribute("class", "alert alert-info");
        document.getElementById("importantInformation").appendChild(divAccounts);
      })
    })

  },


  refreshBalanceOfExchange: function () {
    console.log("refresh balance")
    var self = this;

    var chaindexInstance;

   ChaindexContract.deployed().then(function(instance){
     chaindexInstance = instance;
     return chaindexInstance.getBalance("FIXED");
   }).then(function(value){
     var balance_el = document.getElementById("balanceOfTokenInExchange");
     balance_el.innerHTML = value.toNumber();
     return chaindexInstance.getEthBalanceInWei();
   }).then(function(value){
     var balance_el = document.getElementById("balanceOfEtherInExchange");
     balance_el.innerHTML = web3.fromWei(value,"ether");
   }).catch(function(e){
     console.log(e);
     self.setStatus("Error Getting balances. Check log for details");
   });
  },
  depositEther: function () {},
  withdrawEther: function () {},
  depositToken: function () {},
  withdrawToken: function () {},

  //Trading-specific functionality
  initTrading: function () {
    App.refreshBalanceOfExchange();
    App.broadcastExchangeInfo();
    App.updateOrderBooks();
    App.listenToTradingEvents();
  },
  updateOrderBooks: function () {},
  listenToTradingEvents: function () {},
  sellToken: function () {},
  buyToken: function () {},

  //Token Management/Admin Section
  initTokenManagement: function () {
    console.log('Initialize Token Management');
    App.updateTokenBalance();
    App.watchTokenEvents();
    App.broadcastExchangeInfo();
  },
  updateTokenBalance: function () {
    var tokenInstance;
    console.log('Updating token Balance (updateTokenBalance)');

    FixedTokenContract.deployed().then(function (instance) {
      tokenInstance = instance;
      return tokenInstance.balanceOf.call(account);
    }).then(function (value) {
      console.log('val', value);
      var balance = document.getElementById("balanceOfTokenInToken");
      console.log('updating balance txt',balance.innerText);
      balance.innerText= value.valueOf();
      console.log('updated balance txt',balance.innerText );
    }).catch(function (e) {
      console.log(e);
      App.setStatus('Error getting token balance', e);
    });

  },
  watchTokenEvents: function () {
    //any time an event occurs in the token contract, watch and display

    var tokenInstance;
    FixedTokenContract.deployed().then(function (instance) {


      tokenInstance = instance;
      //watch all events for this token
      tokenInstance.allEvents({},{fromBlock:0, toBlock:'latest'}).watch(function(error,result){
        //build out popup
        var alertBox = document.createElement('div');
        alertBox.setAttribute('class', 'alert alert-info alert-dismissable');
        
        var closeBtn = document.createElement('button');
        closeBtn.setAttribute('type', 'button');
        closeBtn.setAttribute('class', 'close');
        closeBtn.setAttribute('data-dismiss', 'alert');
        closeBtn.innerHTML='<span>&times;</span>';
        alertBox.appendChild(closeBtn);

        var eventTitle = document.createElement('div');
        eventTitle.innerHTML = '<strong>Event:' + result.event+'</strong>';
        alertBox.appendChild(eventTitle);

        //show arguments
        var argsBox = document.createElement('textarea');
        argsBox.setAttribute('class','form-control');
        argsBox.innerText = JSON.stringify(result.args);
        alertBox.appendChild(argsBox);

        //drat to token evens area
        document.getElementById('tokenEvents').appendChild(alertBox);

      })
    }).catch(function (e) {
      console.log(e);
      App.setStatus('Error in events', e);
    });

  },
  addTokenToExchange: function () {
    var tokenSymbolName = document.getElementById('inputTokenNameToAdd').value;
    var tokenContractAddress = document.getElementById('inputTokenAddressToAdd').value;
    App.setStatus("Attempting to add token to exchange (please wait)");

    ChaindexContract.deployed().then(function (instance) {
      return instance.addToken(tokenSymbolName, tokenContractAddress, {from:account});
    }).then(function (txResponse) {
      console.log('token add tx result', txResponse);
      App.setStatus("Tokens added to Exchange.");

    }).catch(function (e) {
      console.log(e);
      App.setStatus('Error adding token to chaindex', e);
    });

  },
  sendToken: function () {

    var amountTokenToSend = parseInt(document.getElementById('inputAmountToSend').value);
    var receiverOfTokens = document.getElementById('inputTokenReceiverAddress').value;
    App.setStatus("Attempting to send token (please wait)");

    var tokenInstance;
    FixedTokenContract.deployed().then(function (instance) {
      tokenInstance = instance;
      return tokenInstance.transfer( receiverOfTokens, amountTokenToSend, {from:account});
    }).then(function (txResponse) {
      console.log('transfer response', txResponse);
      App.setStatus("Tokens sent!");
      App.updateTokenBalance();

    }).catch(function (e) {
      console.log(e);
      App.setStatus('Error sending token', e);
    });
  },
  approveAllowance: function () {
    var self = this;
    var amountTokenToApprove = parseInt(document.getElementById('inputAmountToApprove').value);
    var receiver = document.getElementById('inputTokenApprovalReceiver').value;
    console.log('amountTokenToApprove', amountTokenToApprove)
    self.setStatus("Attempting to approve token (please wait)");

    var tokenInstance;
    FixedTokenContract.deployed().then(function (instance) {
      tokenInstance = instance;

      return tokenInstance.approve( receiver, amountTokenToApprove, {from:account});
    }).then(function () {
      self.setStatus("Allotment of approved for use by chaindex.");
      App.updateTokenBalance();

    }).catch(function (e) {
      console.log(e);
      self.setStatus('Error sending token', e);
    });
  },

  updateTokensApproved: function () {
    var tokenInstance;
    console.log('Updating token approved (updateTokensApproved)');

    FixedTokenContract.deployed().then(function (instance) {
      tokenInstance = instance;
      return tokenInstance.allowed.call(account);
    }).then(function (value) {
      console.log('val', value);
      var balance = document.getElementById("balanceOfTokensApproved");
      balance.innerText= value.valueOf();
    }).catch(function (e) {
      console.log(e);
      App.setStatus('Error getting approved tokens mapping', e);
    });
  }
  
};

window.addEventListener('load', function () {
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