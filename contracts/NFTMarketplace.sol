// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTMarketplace is Initializable {
  address private _admin;

  function initialize() public initializer {
    _admin = msg.sender;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _saleCount;
  Counters.Counter private _totalCount;

  struct MarketItem {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    address seller;
    uint256 price;
    bool isListed;
  }

  // _marketItemsList [nftContract] [tokenId] .props
  mapping(address => mapping(uint256 => MarketItem)) private _marketItemsList;
  mapping(uint256 => MarketItem) private _idToMarketItem;

  // ################### //
  //       EVENTS        //
  // ################### //

  event MarketItemCreateEvent(
    address nftContract,
    uint256 tokenId,
    address seller,
    uint256 price
  );

  event MarketItemUpdatePriceEvent(
    address nftContract,
    uint256 tokenId,
    address seller,
    uint256 price,
    uint256 newPrice
  );

  event MarketItemRemoveEvent(
    address nftContract,
    uint256 tokenId,
    address seller
  );

  event TransferByAdminEvent(
    address nftContract,
    uint256 tokenId,
    address seller,
    address newOwner,
    uint256 buyPrice
  );

  event UpdatePriceByAdminEvent(
    address nftContract,
    uint256 tokenId,
    uint256 oldPrice,
    uint256 newPrice
  );

  event RemoveByAdminEvent(address nftContract, uint256 tokenId);

  // ################### //
  //      MODIFIERS      //
  // ################### //

  // check for NFT owner
  modifier isNFTOwner(address nftContract, uint256 tokenId) {
    require(
      address(nftContract) != address(0),
      "NFT Contract address must be NOT 0x0"
    );

    require(
      ERC721(nftContract).ownerOf(tokenId) == msg.sender,
      "NFT must be owned by sender"
    );
    _;
  }

  // check for Admin
  modifier isAdmin() {
    require(_admin == msg.sender, "Must be only Contract Admin");
    _;
  }

  // check if is listed
  modifier isListed(address nftContract, uint256 tokenId) {
    require(
      _marketItemsList[nftContract][tokenId].isListed,
      "NFT must be listed"
    );
    _;
  }

  // check for price
  modifier checkPrice(uint256 price) {
    require(price > 0, "Price must be greater than 0");
    require(price < 1000000000, "Price must be less than 1 000 000 000");
    _;
  }

  // check if is Approved
  function isApproved(
    address nftContract,
    address owner
  ) private view returns (bool) {
    bool isApprove = ERC721(nftContract).isApprovedForAll(owner, address(this));
    return isApprove;
  }

  // ################### //
  //      NFT OWNED      //
  // ################### //

  // create Market Item - put Up for Sale
  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) external isNFTOwner(nftContract, tokenId) checkPrice(price) {
    require(
      !_marketItemsList[nftContract][tokenId].isListed,
      "NFT must be NOT listed"
    );

    require(
      isApproved(nftContract, msg.sender),
      "NFT must be approved to market"
    );

    _totalCount.increment();
    _saleCount.increment();
    uint256 itemId = _totalCount.current();

    // add to mapping listing
    _marketItemsList[nftContract][tokenId] = MarketItem(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      price,
      true
    );

    _idToMarketItem[itemId] = MarketItem(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      price,
      true
    );

    // add event
    emit MarketItemCreateEvent(nftContract, tokenId, msg.sender, price);
  }

  // update Market Item price
  function updateMarketItemPrice(
    address nftContract,
    uint256 tokenId,
    uint256 newPrice
  )
    external
    isNFTOwner(nftContract, tokenId)
    checkPrice(newPrice)
    isListed(nftContract, tokenId)
  {
    uint256 itemId = _marketItemsList[nftContract][tokenId].itemId;
    uint256 oldPrice = _marketItemsList[nftContract][tokenId].price;

    // update listing price
    _marketItemsList[nftContract][tokenId].price = newPrice;
    _idToMarketItem[itemId].price = newPrice;

    // add event
    emit MarketItemUpdatePriceEvent(
      nftContract,
      tokenId,
      msg.sender,
      oldPrice,
      newPrice
    );
  }

  // remove Market Item
  function removeMarketItem(
    address nftContract,
    uint256 tokenId
  ) external isNFTOwner(nftContract, tokenId) isListed(nftContract, tokenId) {
    uint256 itemId = _marketItemsList[nftContract][tokenId].itemId;

    // remove from listing
    delete _marketItemsList[nftContract][tokenId];
    delete _idToMarketItem[itemId];

    // _totalCount.decrement();
    _saleCount.decrement();

    // add event
    emit MarketItemRemoveEvent(nftContract, tokenId, msg.sender);
  }

  // ################### //
  //       PUBLIC        //
  // ################### //

  // get owner
  function getAdmin() public view returns (address) {
    return _admin;
  }

  // get sale count
  function getSaleCount() public view returns (uint256) {
    return _saleCount.current();
  }

  // get total count
  function getTotalCount() public view returns (uint256) {
    return _totalCount.current();
  }

  // fetch Market Items
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint256 totalCount = _totalCount.current();
    uint256 saleCount = _saleCount.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](saleCount);
    for (uint i = 0; i < totalCount; i++) {
      uint currentId = i + 1;
      if (_idToMarketItem[currentId].isListed) {
        MarketItem storage currentItem = _idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  // get market item
  function getMarketItem(
    address nftContract,
    uint256 tokenId
  ) external view returns (MarketItem memory) {
    return _marketItemsList[nftContract][tokenId];
  }

  // get market item by itemId
  function getMarketItemById(
    uint256 itemId
  ) external view returns (MarketItem memory) {
    return _idToMarketItem[itemId];
  }

  // ################### //
  //       ADMINS        //
  // ################### //

  // transfer by admin  (RUB purchases)
  function transferByAdmin(
    address nftContract,
    uint256 tokenId,
    address newOwner
  ) external isAdmin isListed(nftContract, tokenId) {
    uint256 itemId = _marketItemsList[nftContract][tokenId].itemId;
    address seller = _marketItemsList[nftContract][tokenId].seller;
    uint256 buyPrice = _marketItemsList[nftContract][tokenId].price;

    // check for market approve
    require(isApproved(nftContract, seller), "NFT must be approved to market");

    // safe transfer
    IERC721(nftContract).safeTransferFrom(seller, newOwner, tokenId);

    // remove from listing
    delete _marketItemsList[nftContract][tokenId];
    delete _idToMarketItem[itemId];

    // _totalCount.decrement();
    _saleCount.decrement();

    // add event
    emit TransferByAdminEvent(nftContract, tokenId, seller, newOwner, buyPrice);
  }

  // update Price by admin
  function updatePriceByAdmin(
    address nftContract,
    uint256 tokenId,
    uint256 newPrice
  ) external isAdmin isListed(nftContract, tokenId) checkPrice(newPrice) {
    // old price to event
    uint256 itemId = _marketItemsList[nftContract][tokenId].itemId;
    uint256 oldPrice = _marketItemsList[nftContract][tokenId].price;

    // update listing price
    _marketItemsList[nftContract][tokenId].price = newPrice;
    _idToMarketItem[itemId].price = newPrice;

    // add event
    emit UpdatePriceByAdminEvent(nftContract, tokenId, oldPrice, newPrice);
  }

  // remove by admin
  function removeByAdmin(
    address nftContract,
    uint256 tokenId
  ) external isAdmin isListed(nftContract, tokenId) {
    uint256 itemId = _marketItemsList[nftContract][tokenId].itemId;

    // remove from listing
    delete _marketItemsList[nftContract][tokenId];
    delete _idToMarketItem[itemId];

    // _totalCount.decrement();
    _saleCount.decrement();

    // add event
    emit RemoveByAdminEvent(nftContract, tokenId);
  }
}
