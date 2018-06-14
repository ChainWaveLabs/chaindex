pragma solidity ^0.4.23;

import "./owned.sol";
import "./FixedSupplyToken.sol";

contract Chaindex is owned {

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
    function depositEther() payable public {
        require( balanceEthForAddress[msg.sender] + msg.value >= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] += msg.value;
        emit DepositForEthReceived(msg.sender,msg.value,now);}

    function withdrawEther(uint amountInWei) public {
        require(balanceEthForAddress[msg.sender] - amountInWei >= 0);
        require(balanceEthForAddress[msg.sender] - amountInWei <= balanceEthForAddress[msg.sender]);
        balanceEthForAddress[msg.sender] -= amountInWei;
        msg.sender.transfer(amountInWei);
        emit WithdrawEth(msg.sender,amountInWei,now);}

    function getEthBalanceInWei() constant public returns(uint)  {
        return balanceEthForAddress[msg.sender];}
    //Token Management
    function addToken(string symbolName, address erc20TokenAddress) onlyowner public{
        //check if symbol name is in exhange
        require(!hasToken(symbolName));
        symbolNameIndex ++;
        tokens[symbolNameIndex].symbolName = symbolName;
        tokens[symbolNameIndex].tokenContract = erc20TokenAddress;
        emit TokenAddedToSystem(symbolNameIndex, symbolName, now);
    }

    function hasToken(string symbolName) constant public returns (bool) {
        
        uint8 index = getSymbolIndex(symbolName);
        
        if (index == 0) {
            return false;
        }
            

        return true;
        }
    //returns index of specific token in tokens mapping by name
    function getSymbolIndex(string symbolName) public view returns(uint8) {

        for (uint8 i = 1; i <= symbolNameIndex; i++) {
            if (stringsEqual(tokens[i].symbolName, symbolName)) {
                return i;
            }
        }
            
        return 0;
        }

    //Standard Solidity string comparison function
    function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {
        
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
    function depositToken( string symbolName, uint amount) public {

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
        emit DepositForTokenReceived(msg.sender, index, amount, now);}

    function withdrawToken(string symbolName, uint amount ) public {

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
        emit WithdrawToken(msg.sender, index, amount, now);
    }

    function getBalance(string symbolName) constant public returns (uint) {
        uint8 index = getSymbolIndex(symbolName);
        require(index>0);
        return tokenBalanceForAddress[msg.sender][index];
    }

    //OrderBook - Bids/Buys
    function getBuyOrderBook(string symbolName) constant public returns (uint[], uint[]) {
        //get two arrays - price points and volume per price point
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);

        uint[] memory arrPricesBuy = new uint[](tokens[index].amountBuyPrices);
        uint[] memory arrVolumesBuy = new uint[](tokens[index].amountBuyPrices);

        uint whilePrice = tokens[index].lowestBuyPrice;
        uint counter =0;

        //Go from lowest price to current price and add them into our price + volume arrays.
        //increment both prices and volume array
        if(tokens[index].currentBuyPrice > 0){
       
            while (whilePrice <= tokens[index].currentBuyPrice) {
                arrPricesBuy[counter] = whilePrice; 
                uint volumeAtPrice = 0;
                uint offers_key = 0;

                offers_key = tokens[index].buyBook[whilePrice].offers_key;

                //volume is the sum of all offers in a single price.. iterate thru offers and sum volumeAtPrice
                while (offers_key <= tokens[index].buyBook[whilePrice].offers_length) {
                    volumeAtPrice += tokens[index].buyBook[whilePrice].offers[offers_key].amount;
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
        return (arrPricesBuy, arrVolumesBuy);
        
    }

    //Orderbook - Sells/Asks
    function getSellOrderBook(string symbolName) constant public returns (uint[], uint[]) { 
        uint8 index = getSymbolIndex(symbolName);
        require(index > 0);

        uint[] memory arrPricesSell = new uint[](tokens[index].amountSellPrices);
        uint[] memory arrVolumesSell = new uint[](tokens[index].amountSellPrices);

        uint whilePrice = tokens[index].currentSellPrice;
        uint counter = 0;

        //Go from lowest price to current price and add them into our price + volume arrays.
        //increment both prices and volume array
        if (tokens[index].currentSellPrice > 0) {
        
            while (whilePrice <= tokens[index].highestSellPrice) {
                arrPricesSell[counter] = whilePrice; 
                uint volumeAtPrice = 0;
                uint offers_key = 0;

                offers_key = tokens[index].sellBook[whilePrice].offers_key;

                //volume is the sum of all offers in a single price.. iterate thru offers and sum volumeAtPrice
                while (offers_key <= tokens[index].sellBook[whilePrice].offers_length) {
                    volumeAtPrice += tokens[index].sellBook[whilePrice].offers[offers_key].amount;
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

         return (arrPricesSell, arrVolumesSell);
    }

    //New Bid Order
    function buyToken(string symbolName, uint priceInWei, uint amount) public {
        uint8 tokenNameIndex = getSymbolIndex(symbolName);
        require(tokenNameIndex > 0);
        uint totalAmountEthNecessary = 0;

        if (tokens[tokenNameIndex].amountSellPrices == 0 || tokens[tokenNameIndex].currentSellPrice > priceInWei) {
            //no offers that can fill this, create a new buy offer in orderbook

            totalAmountEthNecessary = amount * priceInWei;

            require(totalAmountEthNecessary >= amount && totalAmountEthNecessary >= priceInWei);
            require(balanceEthForAddress[msg.sender] >= totalAmountEthNecessary);
            require(balanceEthForAddress[msg.sender] - totalAmountEthNecessary >= 0);
            require(balanceEthForAddress[msg.sender] - totalAmountEthNecessary <= balanceEthForAddress[msg.sender]);
            balanceEthForAddress[msg.sender] -= totalAmountEthNecessary;

            addBuyOffer(tokenNameIndex, priceInWei, amount, msg.sender);
            uint offerLen = tokens[tokenNameIndex].buyBook[priceInWei].offers_length;
            emit LimitBuyOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, offerLen);
        } else {
            uint totalAmountEtherAvailable = 0;
            uint whilePrice = tokens[tokenNameIndex].currentSellPrice;
            uint amountNecessary = amount;
            uint offers_key;

            while(whilePrice <= priceInWei && amountNecessary > 0){
                offers_key = tokens[tokenNameIndex].sellBook[whilePrice].offers_key;
                while(offers_key <= tokens[tokenNameIndex].sellBook[whilePrice].offers_length && amountNecessary > 0){
                    uint volumeAtPriceFromAddress = tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount;
                    //if the market buy offer is not enough to fulfill the  order it should be used up completely and move to next offer
                    //otherwise we only partially fill the order and lower offerer amt & fulfill out order
                    if(volumeAtPriceFromAddress <= amountNecessary){
                        require(balanceEthForAddress[msg.sender] >= totalAmountEtherAvailable);
                        require(balanceEthForAddress[msg.sender] - totalAmountEtherAvailable <= balanceEthForAddress[msg.sender]);
                        //reduce senders balance
                        balanceEthForAddress[msg.sender] -= totalAmountEtherAvailable;
                        //check for overflows
                        //check volume that the sender has in their token balance + the volumeAt that price is greater than thheir token balance
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] + volumeAtPriceFromAddress  <= tokenBalanceForAddress[msg.sender][tokenNameIndex]);
                        //check the 
                        require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + totalAmountEtherAvailable >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]); 

                        //person offers less or equal to volume that is asked for, so it is used completely
                        //update token balance of sender, remove offers from sell order book, add eth to balance of sender, and iterate the sell book offers key
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] += volumeAtPriceFromAddress;
                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount = 0; 
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += totalAmountEtherAvailable;
                        tokens[tokenNameIndex].sellBook[whilePrice].offers_key++;
                        
                        emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);

                        amountNecessary -= volumeAtPriceFromAddress;
                    } else {

                        //If market buy offer can fulfil order
                        require(tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount > amountNecessary);
                        uint totalAmountEtherNecessary = amountNecessary * whilePrice;
                        require(balanceEthForAddress[msg.sender] - totalAmountEtherNecessary <= balanceEthForAddress[msg.sender]);
                        
                        //redusce ether from sender's balance
                        balanceEthForAddress[msg.sender] -= totalAmountEtherNecessary;

                        //check that there's enough in the eth in the sellbook offer to handle this transaction
                        require(balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] + totalAmountEtherNecessary >= balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who]); 
                        //sender is offering greater than the sell book ask. the offer gets tokens, the sender gets eth.
                        tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount = amountNecessary;
                        balanceEthForAddress[tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].who] += totalAmountEtherNecessary;
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] += amountNecessary;
                        
                        //reset amnt necessary
                        amountNecessary = 0;
                        emit SellOrderFulfilled(tokenNameIndex, amountNecessary, whilePrice, offers_key);
                    }

                    //check if we have the last offer in the sell book at that price and then reset current buy price lower and reduce offers in sell book.
                    if(offers_key == tokens[tokenNameIndex].sellBook[whilePrice].offers_length && tokens[tokenNameIndex].sellBook[whilePrice].offers[offers_key].amount ==0){
                        tokens[tokenNameIndex].amountSellPrices --;

                        if (whilePrice == tokens[tokenNameIndex].sellBook[whilePrice].higherPrice || tokens[tokenNameIndex].buyBook[whilePrice].higherPrice == 0){
                            tokens[tokenNameIndex].currentSellPrice = 0;
                        } else {
                            tokens[tokenNameIndex].currentSellPrice = tokens[tokenNameIndex].sellBook[whilePrice].higherPrice;
                            tokens[tokenNameIndex].sellBook[tokens[tokenNameIndex].buyBook[whilePrice].higherPrice].lowerPrice = 0;
                        }
                    }
                    offers_key++;
                }//end offers_key while
                whilePrice = tokens[tokenNameIndex].currentSellPrice;
            }//end whilePrice while 

            //if the buyer order requires more volume, then place a limit order
            if(amountNecessary >0){
                buyToken(symbolName, priceInWei, amountNecessary);
            }
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

                while (buyPrice > 0 && !foundSpot) {

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
    function sellToken(string symbolName, uint priceInWei, uint amount) public {
        uint8 tokenNameIndex = getSymbolIndex(symbolName);
        require(tokenNameIndex > 0);
        uint totalAmountEthNecessary = 0;
        uint totalAmountEthAvailable = 0;

        if (tokens[tokenNameIndex].amountBuyPrices == 0 || tokens[tokenNameIndex].currentBuyPrice < priceInWei ) {
            totalAmountEthNecessary = amount * priceInWei;

            require(totalAmountEthNecessary >= amount);
            require(totalAmountEthNecessary >= priceInWei);
            require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amount);
            require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - amount >= 0);
            require(balanceEthForAddress[msg.sender] + totalAmountEthNecessary >= balanceEthForAddress[msg.sender]);

            tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amount;

            //no offers that can fill this, create a new buy offer in orderbook
            addSellOffer(tokenNameIndex, priceInWei, amount, msg.sender);
            emit LimitSellOrderCreated(tokenNameIndex, msg.sender, amount, priceInWei, tokens[tokenNameIndex].sellBook[priceInWei].offers_length);
        } else {
            //working with sell book. trying to find highest buy offer we can find (currentBuyPrice)
            uint whilePrice = tokens[tokenNameIndex].currentBuyPrice;
            uint amountNecessary = amount;
            uint offers_key;

            while (whilePrice >= priceInWei && amountNecessary >0) {
                offers_key = tokens[tokenNameIndex].buyBook[whilePrice].offers_key;

                //walk through offers mapping in buy book while we have an amount left in our sell order
                while(offers_key <= tokens[tokenNameIndex].buyBook[whilePrice].offers_length && amountNecessary > 0){
                    uint volumeAtPriceFromAddress = tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount;
                    
                    // one person offer can't fulfill volume - we use it up then move to next offer for this token
                        
                    if (volumeAtPriceFromAddress <= amountNecessary) {
                        totalAmountEthAvailable = volumeAtPriceFromAddress * whilePrice;

                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= volumeAtPriceFromAddress);
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= volumeAtPriceFromAddress;

                        //check overflows
                        //token seller has volume
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] - volumeAtPriceFromAddress >= 0 );
                        require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] + volumeAtPriceFromAddress >= 
                        tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);

                        require(balanceEthForAddress[msg.sender] + totalAmountEthAvailable >= balanceEthForAddress[msg.sender]);
                        //an offer less or equal to the askable volume, so use up volume completely.

                        //process transaction & iterate current offer key
                        //add tokens toe balance of those who want to buy them
                        tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += volumeAtPriceFromAddress;
                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount = 0;
                        balanceEthForAddress[msg.sender] += totalAmountEthAvailable;
                        tokens[tokenNameIndex].buyBook[whilePrice].offers_key ++;

                        emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);
                        amountNecessary -= volumeAtPriceFromAddress;
                    } else {
                        // alternatively, we use part of what person is offering, decrease his amt, then fulfill the order
                        //offer has more than we are trying to sell for
                        require(volumeAtPriceFromAddress - amountNecessary > 0);
                        totalAmountEthNecessary = amountNecessary + whilePrice; //total needed is the amt at current iterated price in order book
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountNecessary);
                        tokenBalanceForAddress[msg.sender][tokenNameIndex] -= amountNecessary;

                        //require that we have enough balaance in the exchange 
                        require(tokenBalanceForAddress[msg.sender][tokenNameIndex] >= amountNecessary);
                        //ensure balance has enough eth to cover the amout needed
                        require(balanceEthForAddress[msg.sender] + totalAmountEthNecessary >= balanceEthForAddress[msg.sender]);
                        require(tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]+ amountNecessary >= tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex]);

                        //Process transaction
                        tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount -= amountNecessary;
                        balanceEthForAddress[msg.sender] += totalAmountEthNecessary;
                        tokenBalanceForAddress[tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].who][tokenNameIndex] += amountNecessary;

                        emit SellOrderFulfilled(tokenNameIndex, volumeAtPriceFromAddress, whilePrice, offers_key);
                        amountNecessary = 0;
                    }

                    //if this was last offer at that price, we need to reorder the currentbuy price and reduce amt of offers in key;
                    if (offers_key == tokens[tokenNameIndex].sellBook[whilePrice].offers_length &&
                    tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amount == 0) {
                       // tokens[tokenNameIndex].buyBook[whilePrice].offers[offers_key].amountBuyPrice --;
                          tokens[tokenNameIndex].amountSellPrices--;
                        if (whilePrice == tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice ||
                        tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice == 0 ) {
                            tokens[tokenNameIndex].currentBuyPrice = 0;
                        } else {
                            //rem last element from llist and set higher element to prev element
                            tokens[tokenNameIndex].currentBuyPrice = tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice;
                            tokens[tokenNameIndex].buyBook[tokens[tokenNameIndex].buyBook[whilePrice].lowerPrice].higherPrice = tokens[tokenNameIndex].currentBuyPrice;
                        }
                    }
                    offers_key++;
                }//ENDWHILE
                whilePrice = tokens[tokenNameIndex].currentBuyPrice;
            
            }//END OUTER WHILE
            if (amountNecessary > 0) {
                //add a limit order of we could not fulfill all of the market orders
                sellToken(symbolName, priceInWei,amountNecessary);
            }

        }
    }

 

    function addSellOffer(uint8 tokenNameIndex, uint priceInWei, uint amount, address who) internal {
        tokens[tokenNameIndex].sellBook[priceInWei].offers_length ++;
        tokens[tokenNameIndex].sellBook[priceInWei].offers[tokens[tokenNameIndex].sellBook[priceInWei].offers_length] = Offer(amount, who);

        //in the order book, we need to reorder the linked list of orders based on a new buy offer coming in
        if (tokens[tokenNameIndex].sellBook[priceInWei].offers_length == 1) {
            tokens[tokenNameIndex].sellBook[priceInWei].offers_key = 1;
            tokens[tokenNameIndex].amountSellPrices ++;

            uint currentSellPrice = tokens[tokenNameIndex].currentSellPrice;
            uint highestSellPrice = tokens[tokenNameIndex].highestSellPrice;
            

            if (highestSellPrice == 0 || highestSellPrice < priceInWei) {
                ///the sell offer is the highest one
                if (currentSellPrice == 0) {
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
    //offerKey here is basically the offers_length when adding a buy/sell order caught from FE.
    // Issue here is that if the user logs out or FE doesn't store this we may need another lookup.
    function cancelOrder(string symbolName,  bool isSellOrder, uint priceInWei, uint offerKey) public {
        
        uint8 tokenNameIndex = getSymbolIndex(symbolName);
        require(tokenNameIndex > 0);

        // To retrieve aon offer by token, key, and price:
        // tokens[tokenNameIndex].buyBook[priceInWei].offers[offerKey]

        if (isSellOrder) {
            //1.look into the sell order book at the address of this offer key make sure its msg.sender
            require(tokens[tokenNameIndex].sellBook[priceInWei].offers[offerKey].who == msg.sender);
            //2. get amt of tokens in the offer
            uint amountOfTokens = tokens[tokenNameIndex].sellBook[priceInWei].offers[offerKey].amount;
            //3. add tokens back to address' balance
            tokenBalanceForAddress[msg.sender][tokenNameIndex] += amountOfTokens;
            //4. remove from sell book
            tokens[tokenNameIndex].sellBook[priceInWei].offers[offerKey].amount = 0;
            //5. Event
            emit SellOrderCancelled(tokenNameIndex, priceInWei,offerKey);


        } else {

            // Basically, refund ether and remove the 'amount' from the offer at key , priceInWei

            require(tokens[tokenNameIndex].buyBook[priceInWei].offers[offerKey].who == msg.sender);
            uint ethToRefund = tokens[tokenNameIndex].buyBook[priceInWei].offers[offerKey].amount * priceInWei;

            //overflow check
            require(balanceEthForAddress[msg.sender] + ethToRefund >= balanceEthForAddress[msg.sender]);

            //inccrease balance in contract
            balanceEthForAddress[msg.sender] += ethToRefund;

            //remove amount in buy book
            tokens[tokenNameIndex].buyBook[priceInWei].offers[offerKey].amount = 0;

            // Event
            emit BuyOrderCancelled(tokenNameIndex, priceInWei, offerKey);
        }

    }
}