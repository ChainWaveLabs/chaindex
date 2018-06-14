pragma solidity ^0.4.23;

//This factory allows contract owner to create a new subscription for a specific asset 
// As new assets are added, we can call the factory to create a new asset
//MVP = ~ 1 day / 5082 blocks
contract ChainCap {
    address owner;
    bool paused;

    uint subscriptionPrice;
    uint durationInBlocks;

    enum Status { ACTIVE, DISABLED, PENDING }

    struct Asset {
        string symbol;
        bool isActive;
        uint lastSubscriptionBlock;
    }

    mapping(uint => Asset) public assets;
    uint public assetCount;


    struct Subscription {
        address subscriberAddr;
        uint assetId;
        uint blockStart;
        uint blockEnd;
    }

    mapping(uint => Subscription) public subscriptions;
    uint public subscriptionCount;
   
    //@dev : constructor - sets contract owner
    constructor() public {
        owner = msg.sender;
    }

    //MODIFIERS 
    modifier onlyOwner() {
        assert(owner == msg.sender);
        _;
    }

    modifier whenNotPaused(){
        require(!paused);
        _;
    }

    modifier assetDoesNotExist(string symbol) {
        require(assetIdLookupBySymbol(symbol)==0);
        _;
    }

    modifier assetExists(string symbol) {
        require (assetIdLookupBySymbol(symbol)>0);
        _;
    }
  
    //retur
    function assetIdLookupBySymbol(string symbol) public view returns(uint){
        for (uint i = 1; i<=assetCount; i++) {
            if(stringsEqual(assets[i].symbol, symbol)){
                return i;
            }
        }
        return 0;
    }

    modifier isNotSubscribed(string assetSymbol, address subscriber) {
        require(!subscriptionCheck(assetSymbol, subscriber));
        _;
    }

    modifier isSubscribed(string assetSymbol, address subscriber) {
        require(subscriptionCheck(assetSymbol, subscriber));
        _;
    }

    //@dev checks to see if a subscription exists w/ asset and address
    function subscriptionCheck(string assetSymbol, address subscriber) public view returns(bool){
        for (uint i = 1; i<=subscriptionCount; i++) {
            if(subscriptions[i].subscriberAddr == subscriber){
                if(subscriptions[i].assetId == assetIdLookupBySymbol(assetSymbol)) {
                    return true;
                }
            }
        }
        return false;
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

    //EVENTS


    //ADMINISTRATIVE
   
    //updates subscription price - only affects new subs=≠=
  

    event AssetAdded(string _symbol, uint indexed _id, uint indexed _timestamp);

    function addAsset(string symbol)
     public 
     onlyOwner()
     assetDoesNotExist(symbol) 
     returns (uint assetId){
      /// TODO figure out why this is throwign invalid opcode:
      // require(!hasAsset(symbol));
        assetCount ++;
        assets[assetCount] = Asset({
            symbol:symbol,
            isActive: true,
            lastSubscriptionBlock: 0
        });
        
        
        emit AssetAdded(symbol, assetId, now);
    }

    function getNumberAssets() public view returns (uint count){
        return assetCount;
    }

    function getOwner() public view returns(address) { 
        return owner;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }
    
    function updateSubscriptionDurationLimit(uint newDuration) private onlyOwner() returns(uint) {
        durationInBlocks = newDuration;
        return durationInBlocks;
    }

    function getSubscriptionDurationLimit() constant public returns(uint){
        return durationInBlocks;
    }

    function updateSubscriptionPrice(uint newPrice) private onlyOwner() returns(uint) {
        subscriptionPrice = newPrice;
        return subscriptionPrice;
    }

    function getSubscriptionPrice() constant public returns(uint){
        return subscriptionPrice;
    }

    function transferOwnership (address newOwner) public onlyOwner() {
        owner = newOwner;
    }

    //Admin can remove asset. However, the asset can only be removed from state  AFTER the last subscription expires
    //The function loooks at the last block a subscription has to this asset and sets the expiration time
    //This is to avoid the ability for admin to add assets, gain subscriber's money, then remove instantly
    // function removeAsset() private {
    // }

    //SUBSCRIPTIONS
    ///User subscribes to an asset for approximately 7 days blocktime for $5

    event NewSubscription(string _symbol, address _subscriber, uint _timestamp);
   
    function subscribeTo (string assetSymbol) 
        public 
        assetExists(assetSymbol)
        isNotSubscribed(assetSymbol, msg.sender) 
        payable {

        subscriptionCount ++;
        subscriptions[subscriptionCount] = Subscription({
            subscriberAddr: msg.sender,
            assetId: assetIdLookupBySymbol(assetSymbol),
            blockStart: block.number + 1,
            blockEnd: block.number + 5083 // 5083 = approximately 1 day
        });
        subscriptionCount ++;

        //update associated asset with the last subscription block so that we can 
        //disable
       // updateLastSubscriptionBlockForAsset(assetSymbol,block.number+5083);

        emit NewSubscription(assetSymbol, msg.sender, now);
    }

    event UpdatedLastSubscriptionBlock (string _symbol, uint _lastBlock);
   
    function updateLastSubscriptionBlockForAsset(string symbol, uint lastBlock) internal{
        uint assetId = assetIdLookupBySymbol(symbol);
        assets[assetId].lastSubscriptionBlock = lastBlock;
        emit UpdatedLastSubscriptionBlock(symbol, lastBlock);
    }

    function() public whenNotPaused() payable {}
}