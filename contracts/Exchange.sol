pragma solidity ^0.4.18;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Exchange is owned {

    struct Offer {
        uint amount;
        address who;
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
        uint amountBuyPrices;

        mapping(uint => OrderBook) sellBook;

        uint currentSellPrice;
        uint highestSellPrice;
        uint amountSellPrices;
    }

    mapping(uint8 => Token) tokens;
    uint8 symbolNameIndex;

    //Balance Management
    mapping(address => mapping(uint8 => uint)) tokenBalanceForAddress;
    mapping(address => uint) balanceEthForAddress;

    //Event Management
    event TokenAddedToSystem(uint _symbolIndex, string _token, uint _timestamp);
    event DepositForTokenReceived(address indexed _from, uint indexed _symbolIndex, uint _amount, uint _timestamp);
    event WithdrawToken(address indexed _to, uint indexed _symbolIndex, uint _amount, uint _timestamp);
   
    event DepositForEthReceived(address indexed _from, uint _amount, uint _timestampe);
    event WithdrawEth(address indexed _to, uint _amount, uint _timestamp);

    event LimitSellOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);
    event SellOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);
    event SellOrderCancelled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);
    
    event LimitBuyOrderCreated(uint indexed _symbolIndex, address indexed _who, uint _amountTokens, uint _priceInWei, uint _orderKey);
    event BuyOrderFulfilled(uint indexed _symbolIndex, uint _amount, uint _priceInWei, uint _orderKey);
    event BuyOrderCancelled(uint indexed _symbolIndex, uint _priceInWei, uint _orderKey);

    //Ether Management
    function depositEther() payable {
        require( balanceEthForAddress[msg.sender] + msg.value >= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] += msg.value;
        DepositForEthReceived(msg.sender,msg.value,now);}

    function withdrawEther(uint amountInWei) {
        require(balanceEthForAddress[msg.sender] - amountInWei >= 0);
        require(balanceEthForAddress[msg.sender] - amountInWei <= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] -= amountInWei;
        msg.sender.transfer(amountInWei);
        WithdrawEth(msg.sender,amountInWei,now);}

    function getEthBalanceInWei() constant returns(uint)  {
        return balanceEthForAddress[msg.sender];}
    //Token Management
    function addToken(string  symbolName, address erc20TokenAddress) onlyowner {
        //check if symbol name is in exhange
        require(!hasToken(symbolName));
        symbolNameIndex ++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
        TokenAddedToSystem(symbolNameIndex, symbolName, now);}

    function hasToken(string symbolName) constant returns (bool) {
        
        uint8 index = getSymbolIndex(symbolName);
        
        if (index == 0) {
            return false;
        }
            

        return true;}
    //returns index of specific token in tokens mapping by name
    function getSymbolIndex(string symbolName) internal returns(uint8) {

        for (uint8 i = 1; i <= symbolNameIndex; i++) {
            if (stringsEqual(tokens[i].symbolName, symbolName)) {
                return i;
            }
        }
            
        return 0;}

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
        return true;}

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
        DepositForTokenReceived(msg.sender, index, amount, now);}

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
        WithdrawToken(msg.sender, index, amount, now);
        }

    function getBalance(string symbolName) constant returns (uint) {
        uint8 index = getSymbolIndex(symbolName);
        require(index>0);
        return tokenBalanceForAddress[msg.sender][index];
        }

    
    
    //OrderBook - Bids/Buys
    function getBuyOrderBook(string symbolName) constant returns (uint[], uint[]) {
        //get two arrays - price points and volume per price point
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);

        uint[] memory arrPricesBuy = new uint[](tokens[index].amountBuyPrices);
        uint[] memory arrVolumesBuy = new uint[](tokens[index].amountBuyPrices);

        uint whilePrice = tokens[index].lowestBuyPrice;
        uint counter =0;

        //Go from lowest price to current price and add them into our price + volume arrays.
        //increment both prices and volume array
        while (tokens[index].currentBuyPrice > 0) {
            arrPricesBuy[counter] = whilePrice; 
            uint volumeAtPrice = 0;
            uint offers_key = 0;

            offers_key = tokens[index].buyBook[whilePrice].offers_key;

            //volume is the sum of all offers in a single price.. iterate thru offers and sum volumeAtPrice
            while (offers_key <= tokens[index].buyBook[whilePrice].offers_length) {
                volumeAtPrice = tokens[index].buyBook[whilePrice].offers[offers_key].amount;
                offers_key++;
            }
            arrVolumesBuy[counter] = volumeAtPrice;
            //when the whilePrice hits the higher price of given book, we break
            //otherwise set the while price to the higher price of the given book.
            if (whilePrice == tokens[index].buyBook[whilePrice].higherPrice) {
             break;
            } else {
                whilePrice = tokens[index].buyBook[whilePrice].higherPrice;
            }
            counter++;
        }
    }

    //Orderbook - Sells/Asks
    function getSellOrderBook(string symbolName) constant returns (uint[], uint[]) { 
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);

        uint[] memory arrPricesSell = new uint[](tokens[index].amountSellPrices);
        uint[] memory arrVolumesSell = new uint[](tokens[index].amountSellPrices);

        uint whilePrice = tokens[index].currentSellPrice;
        uint counter = 0;

        //Go from lowest price to current price and add them into our price + volume arrays.
        //increment both prices and volume array
        while (tokens[index].currentSellPrice < 0) {
            arrPricesSell[counter] = whilePrice; 
            uint volumeAtPrice = 0;
            uint offers_key = 0;

            offers_key = tokens[index].sellBook[whilePrice].offers_key;

            //volume is the sum of all offers in a single price.. iterate thru offers and sum volumeAtPrice
            while (offers_key <= tokens[index].sellBook[whilePrice].offers_length) {
                volumeAtPrice = tokens[index].sellBook[whilePrice].offers[offers_key].amount;
                offers_key++;
            }
            arrVolumesSell[counter] = volumeAtPrice;
            //when the whilePrice hits the higher price of given book, we break
            //otherwise set the while price to the higher price of the given book.
            if (0 == tokens[index].sellBook[whilePrice].higherPrice) {
             break;
            } else {
                whilePrice = tokens[index].sellBook[whilePrice].higherPrice;
            }
            counter++;
        }
    }

    //New Bid Order
    function buyToken(string symbolName, uint priceInWei, uint amount) {
        uint8 tokenNameIndex = getSymbolIndex(symbolName);
        require(tokenNameIndex > 0);
        uint total_amount_eth_necessary = 0;
        uint total_amount_eth_available = 0;

        total_amount_eth_necessary = amount * priceInWei;

        require(total_amount_eth_necessary >= amount && total_amount_eth_necessary >= priceInWei);
        require(balanceEthForAddress[msg.sender] >= total_amount_eth_necessary);
        require(balanceEthForAddress[msg.sender] - total_amount_eth_necessary >= 0);

        balanceEthForAddress[msg.sender] -= total_amount_eth_necessary;

        if(tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].currentSellPrice > priceInWei ){
            //no offers that can fill this, create a new buy offer in orderbook
            addBuyOffer(tokenNameIndex, priceInWei, amount, msg.sender);
            LimitBuyOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].buyBook[priceInWei].offers_length);
        } else {
            //TODO: market order
            revert();
        }
    }

    function addBuyOffer(uint8 tokenNameIndex, uint priceInWei, uint amount, address who) internal {
        tokens[tokenNameIndex].buyBook[priceInWei].offers_length ++;
        tokens[tokenNameIndex].buyBook[priceInWei].offers[tokens[tokenNameIndex].buyBook[priceInWei].offers_length] = Offer(amount, who);

        //in the order book, we need to reorder the linked list of orders based on a new buy offer coming in
        if (tokens[tokenNameIndex].buyBook[priceInWei].offers_length == 1) {
            tokens[tokenNameIndex].buyBook[priceInWei].offers_key = 1;
            tokens[tokenNameIndex].amountBuyPrices ++;

            uint currentBuyPrice = tokens[tokenNameIndex].currentBuyPrice;
            uint lowestBuyPrice = tokens[tokenNameIndex].lowestBuyPrice;
            

            if(lowestBuyPrice == 0 || lowestBuyPrice > priceInWei) {
                ///the buy offer is the lowest one
                if(currentBuyPrice == 0){
                    //no order exists must create new
                    tokens[tokenNameIndex].currentBuyPrice = priceInWei;
                    tokens[tokenNameIndex].buyBook[priceInWei].higherPrice = priceInWei;
                    tokens[tokenNameIndex].buyBook[priceInWei].lowerPrice = 0;
                } else {
                    tokens[tokenNameIndex].buyBook[lowestBuyPrice].lowerPrice = priceInWei;
                    tokens[tokenNameIndex].buyBook[priceInWei].higherPrice = lowestBuyPrice;
                    tokens[tokenNameIndex].buyBook[priceInWei].lowerPrice = 0;
                }
                tokens[tokenNameIndex].lowestBuyPrice = priceInWei;
            } else if (currentBuyPrice < priceInWei) {
                //if the offer is the highest, we don't need to reorder thes list, just append it
                    tokens[tokenNameIndex].buyBook[currentBuyPrice].higherPrice = priceInWei;
                    tokens[tokenNameIndex].buyBook[priceInWei].higherPrice = priceInWei;
                    tokens[tokenNameIndex].buyBook[priceInWei].lowerPrice = currentBuyPrice;
                    tokens[tokenNameIndex].currentBuyPrice = priceInWei;
            } else {
                //the buy order is in the middle, so we need to find the spot in the linked list then reorder everything

                //find correct spot in book
                uint buyPrice = tokens[tokenNameIndex].currentBuyPrice;
                bool foundSpot = false;

                while(buyPrice > 0 && !foundSpot){

                    if (buyPrice < priceInWei && tokens[tokenNameIndex].buyBook[buyPrice].higherPrice > priceInWei){
                        //set new order book entry high/low first
                        tokens[tokenNameIndex].buyBook[priceInWei].lowerPrice = buyPrice;
                        tokens[tokenNameIndex].buyBook[priceInWei].higherPrice = tokens[tokenNameIndex].buyBook[buyPrice].higherPrice;

                        //set the higer priced order book entries' lowerPrice to the current price
                        tokens[tokenNameIndex].buyBook[tokens[tokenNameIndex].buyBook[buyPrice].higherPrice].lowerPrice = priceInWei;

                        //set the lower priced book entries' higerPrice ot the current
                        tokens[tokenNameIndex].buyBook[buyPrice].higherPrice = priceInWei;

                        foundSpot = true;
                    }

                    buyPrice = tokens[tokenNameIndex].buyBook[buyPrice].lowerPrice;
                }
            
            }

        }
    }

    //New Ask Order
    function sellToken(string symbolName, uint priceInWei, uint amount) {
        uint8 tokenNameIndex = getSymbolIndex(symbolName);
        require(tokenNameIndex > 0);
        uint total_amount_eth_necessary = 0;
        uint total_amount_eth_available = 0;

        total_amount_eth_necessary = amount * priceInWei;

        require(total_amount_eth_necessary >= amount && total_amount_eth_necessary >= priceInWei);
        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= total_amount_eth_necessary);
        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - total_amount_eth_necessary >= 0);
        require(balanceEthForAddress[msg.sender] + total_amount_eth_necessary >= balanceEthForAddress[msg.sender]);

        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amount;

        if (tokens[tokenNameIndex].amountBuyPrices == 0 || tokens[tokenNameIndex].currentBuyPrice < priceInWei ) {
            //no offers that can fill this, create a new buy offer in orderbook
            addSellOffer(tokenNameIndex, priceInWei, amount, msg.sender);
            LimitSellOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].sellBook[priceInWei].offers_length);
        } else {
            //TODO: market order
            revert();
        }
    }

    function addSellOffer(uint8 tokenNameIndex, uint priceInWei, uint amount, address who) internal {
        tokens[tokenNameIndex].sellBook[priceInWei].offers_length ++;
        tokens[tokenNameIndex].sellBook[priceInWei].offers[tokens[tokenNameIndex].sellBook[priceInWei].offers_length] = Offer(amount, who);

        //in the order book, we need to reorder the linked list of orders based on a new buy offer coming in
        if (tokens[tokenNameIndex].sellBook[priceInWei].offers_length == 1) {
            tokens[tokenNameIndex].sellBook[priceInWei].offers_key = 1;
            tokens[tokenNameIndex].amountBuyPrices ++;

            uint currentSellPrice = tokens[tokenNameIndex].currentSellPrice;
            uint highestSellPrice = tokens[tokenNameIndex].highestSellPrice;
            

            if(highestSellPrice == 0 || highestSellPrice < priceInWei) {
                ///the sell offer is the highest one
                if(currentSellPrice == 0){
                    //no order exists must create new
                    tokens[tokenNameIndex].currentSellPrice = priceInWei;
                    tokens[tokenNameIndex].sellBook[priceInWei].higherPrice = 0;
                    tokens[tokenNameIndex].sellBook[priceInWei].lowerPrice = 0;
                } else {
                    //Highest priced sell order:
                    tokens[tokenNameIndex].sellBook[highestSellPrice].lowerPrice = priceInWei;
                    tokens[tokenNameIndex].sellBook[priceInWei].higherPrice = highestSellPrice;
                    tokens[tokenNameIndex].sellBook[priceInWei].lowerPrice = 0;
                }
                tokens[tokenNameIndex].lowestBuyPrice = priceInWei;
            } else if (currentSellPrice > priceInWei) {
                //if the ask offer is the lowest offer to sell,
                    tokens[tokenNameIndex].sellBook[currentSellPrice].higherPrice = priceInWei;
                    tokens[tokenNameIndex].sellBook[priceInWei].higherPrice = currentSellPrice;
                    tokens[tokenNameIndex].sellBook[priceInWei].lowerPrice = 0;
                    tokens[tokenNameIndex].currentSellPrice = priceInWei;
            } else {
                //the buy order is in the middle, so we need to find the spot in the linked list then reorder everything

                //find correct spot in book
                uint sellPrice = tokens[tokenNameIndex].currentSellPrice;
                bool foundSpot = false;

                while(sellPrice > 0 && !foundSpot){

                    if (currentSellPrice < priceInWei && tokens[tokenNameIndex].sellBook[sellPrice].higherPrice > priceInWei){
                        //set new order book entry high/low first
                        tokens[tokenNameIndex].sellBook[priceInWei].lowerPrice = sellPrice;
                        tokens[tokenNameIndex].sellBook[priceInWei].higherPrice = tokens[tokenNameIndex].sellBook[sellPrice].higherPrice;

                        //set the higer priced order book entries' lowerPrice to the current price
                        tokens[tokenNameIndex].sellBook[tokens[tokenNameIndex].sellBook[sellPrice].higherPrice].lowerPrice = priceInWei;

                        //set the lower priced book entries' higerPrice ot the current
                        tokens[tokenNameIndex].sellBook[sellPrice].higherPrice = priceInWei;

                        foundSpot = true;
                    }

                    sellPrice = tokens[tokenNameIndex].sellBook[sellPrice].higherPrice;
                }
            
            }

        }
    }
    //cancels limit order
    function cancelOrder(string symbolName,  bool isSellOrder, uint priceInWei, uint offerKey) {}
}