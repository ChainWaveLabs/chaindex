pragma solidity ^0.4.18;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is owned {

    struct Offer {
        address who;
        uint amount;
    }

    struct OrderBook {
        //linked list to and from higher/lower
        uint higherPrice;
        uint lowerPrice;

        //Stack of offers
        mapping(uint => Offer) offers;

        uint offers_key;
        uint offers_length;
    }

    struct Token {
        address tokenContract;
        string symbolName;

        mapping(uint => OrderBook) buyBook;

        uint currentBuyPrice;
        uint lowestBuyPrice;
        uint amountBuyPrice;

        mapping(uint => OrderBook) sellBook;

        uint currentSellPrice;
        uint lowestSellPrice;
        uint amountSellPrice;
    }

    mapping(uint8 => Token) tokens;
    uint8 symbolNameIndex;

    //Balance Management
    mapping(address => mapping(uint8 => uint)) tokenBalanceForAddress;
    mapping(address => uint) balanceEthForAddress;

    //Event Management

    //Ether Management
    function depositEther() payable {
        require( balanceEthForAddress[msg.sender] + msg.value >= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] += msg.value;
    }

    function withdrawEther(uint amountInWei) {
        require(balanceEthForAddress[msg.sender] - amountInWei >= 0);
        require(balanceEthForAddress[msg.sender] - amountInWei <= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] -= amountInWei;
        msg.sender.transfer(amountInWei);
    }

    function getEtherBalanceInWei() constant returns(uint)  {
        return balanceEthForAddress[msg.sender];
    }
    //Token Management

    function addToken(string  symbolName, address erc20TokenAddress) onlyowner {
        //check if symbol name is in exhange
        require(!hasToken(symbolName));
        symbolNameIndex ++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
    }

    function hasToken(string symbolName) constant returns (bool) {
        
        uint8 index = getSymbolIndex(symbolName);
        
        if (index == 0) {
            return false;
        }
            

        return true;
    }

    //returns index of specific token in tokens mapping by name
    function getSymbolIndex(string symbolName) internal returns(uint8) {

        for (uint8 i = 1; i <= symbolNameIndex; i++) {
            if (stringsEqual(tokens[i].symbolName, symbolName)) {
                return i;
            }
        }
            
        return 0;
    }

    //Utility
    //Standard Solidity string comparison function
    function stringsEqual(string storage _a, string memory _b) internal returns (bool) {
        
        //cast to bytes
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);

        if (a.length != b.length)
             return false;

        for(uint i = 0; i < a.length; i++) {
            if(a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    //Token Depoist and Withdrawal

    function depositToken( string symbolName, uint amount) {

        //get token index & contract address
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);

        address erc20TokenContract = tokens[index].tokenContract;
        require(erc20TokenContract != address(0));

        //Interface via ERC20 Standard
        ERC20Interface token = ERC20Interface(erc20TokenContract);
        
        require(token.transferFrom(msg.sender, address(this), amount) == true);
        require(tokenBalanceForAddress[msg.sender][index] + amount >= tokenBalanceForAddress[msg.sender][index]);
        tokenBalanceForAddress[msg.sender][index] += amount;
    }

    function withdrawToken(string symbolName, uint amount ) {

        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);

        address erc20TokenContract = tokens[index].tokenContract;
        require(erc20TokenContract != address(0));

         //Interface via ERC20 Standard
        ERC20Interface token = ERC20Interface(erc20TokenContract);

        require(tokenBalanceForAddress[msg.sender][index] - amount >= 0);
        require(tokenBalanceForAddress[msg.sender][index] - amount <= tokenBalanceForAddress[msg.sender][index]);
        tokenBalanceForAddress[msg.sender][index] -= amount;
        require(token.transfer(msg.sender, amount) == true);
    }

    function getBalance(string symbolName) constant returns (uint) {
        uint8 index = getSymbolIndex(symbolName);
        require(index>0);
        return tokenBalanceForAddress[msg.sender][index];
    }

    //OrderBook - Bids/Buys
    function getBuyOrderBook(string symbolName) constant returns (uint[], uint[]) {

    }
    //Orderbook - Sells/Asks
    function getSellOrderBook(string symbolName) constant returns (uint[], uint[]) {

    }

    //New Bid Order

    function buyToken(string symbolName, uint priceInWei, uint amount) {

    }
    //New Ask Order
    function sellToken(string symbolName, uint priceInWei, uint amount) {

    }

    //cancels limit order
    function cancelOrder(string symbolName,  bool isSellOrder, uint priceInWei, uint offerKey) {

    }
}