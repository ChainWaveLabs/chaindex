pragma solidity ^0.4.18;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is owned {

    struct Offer {

    }

    struct OrderBook {

    }

    struct Token {

    }

    mapping(uint8 => Token) tokens;
    uint8 symbolNameIndex;

    //Balance Management
    mapping(address => mapping(uint8 => uint)) tokenBalanceForAddress;
    mapping(address => uint) balanceEthForAddress;

    //Event Management

    //Ether Management
    function depositEther() payable {

    }

    function withdrawEther(uint amountInWei){

    }

    function getEtherBalanceInWei() constant returns(uint){

    }
    //Token Management

    function addToken(string  symbolName, address erc20TokenAddress) onlyOwner{

    }

    function hasToken(string symbolName) constant returns (bool){

    }

    function getSymbolIndex(string symbolName) internal returns(uint8){
        
    }

    //Token Depoist and Withdrawal

    function depositToken( string symbolName, uint amount){

    }

    function withdrawToken(string symbolName, uint amount ){

    }

    function getBalance(string symbolName) constant returns (uint){

    }

    //OrderBook - Bids/Buys
    function getBuyOrderBook(string symbolName) constant returns (uint[], uint[]){

    }
    //Orderbook - Sells/Asks
    function getSellOrderBook(string symbolName) consant returns (uint[], uint[]){

    }

    //New Bid Order

    function buyToken(string symbolName, uint priceInWei, uint, amount){

    }
    //New Ask Order
    function sellToken(string symbolName, uint priceInWei, uint, amount){

    }

    //cancels limit order
    function cancelOrder(string symbolName,  bool isSellOrder, uin priceInWei,, uint offerKey){

    }
}