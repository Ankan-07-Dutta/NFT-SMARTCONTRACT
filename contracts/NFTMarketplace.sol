// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

//INTERNAL IMPORT FOR NFT OPENZIPLINE
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NFTMarketplace is ERC721URIStorage{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.0015 ether;

    address payable owner;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated (
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner{
        require(msg.sender == owner, "only owner of the market place can change the listing price");
        _;
    }

    constructor() ERC721("NFT Metavarse Token", "MYNFT"){
        owner = payable(msg.sender);
    }

    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    // Let create "CREATE NFT TOKEN FUNCTION"

    function createToken(string memory tokenURI, uint256 price) public payable returns(uint256){
        require(bytes(tokenURI).length > 0, "Empty tokenURI");
        require(msg.value >= listingPrice, "Insufficient listing fee");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        // Return excess ETH if sent too much
        if(msg.value > listingPrice) {
            payable(msg.sender).transfer(msg.value - listingPrice);
        }
        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    //CREATING MARKET ITEM
    function createMarketItem(uint256 tokenID, uint256 price) private{
        require(price > 0, "Price must be greater than zero");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        require(IERC721(address(this)).ownerOf(tokenID) == msg.sender, "Not token owner");

        idMarketItem[tokenID] = MarketItem(
            tokenID,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenID);

        emit idMarketItemCreated( tokenID, msg.sender, address(this), price, false);
    }

    //FUNCTION FOR RESALE TOKEN
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(idMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this operation");

        require(msg.value == listingPrice, "Price must be equal to listing price");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer( msg.sender, address(this), tokenId);
    }

    //FUNCTION CREATEMARKETSALE

    function createMarketSale(uint256 tokenID) public payable{
        uint256 price = idMarketItem[tokenID].price;

        require(msg.value == price,
         "Please submit the asking price in order to complete the purchase ");

         idMarketItem[tokenID].owner = payable(msg.sender);
         idMarketItem[tokenID].sold = true;
         //idMarketItem[tokenID].owner = payable(address(0));

         _itemsSold.increment();

         _transfer(address(this), msg.sender, tokenID);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenID].seller).transfer(msg.value);
    }


    //GETTING UNSOLD NFT DATA
    function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i =0; i< itemCount; i++){
            if(idMarketItem[i+1].owner == address(this)) {
                uint256 currentId = i +1;
                
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return items;
    }

    //PURCHASE ITEM
    function fetchMyNFT() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i =0; i< totalCount; i++){
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i =0; i< totalCount; i++){

            if(idMarketItem[i+1].owner == msg.sender){
                uint256 currentId = i+1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return items;
    }

    //SINGLE USER ITEMS
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i =0; i< totalCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount) ;
        for(uint256 i =0; i< totalCount; i++) {
            if(idMarketItem[i+1].seller == msg.sender){
                uint256 currentId = i+1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}