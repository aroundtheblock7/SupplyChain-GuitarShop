// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./SafeMath.sol";

contract GuitarShop {
    using SafeMath for uint256;

    address payable owner;
    uint256 public skuCount;

    mapping(uint256 => Item) public items;

    constructor() {
        owner = payable(msg.sender);
        skuCount = 0;
    }

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

    struct Item {
        string name;
        uint256 price;
        uint256 sku;
        address payable seller;
        address payable buyer;
        State state;
    }

    //events
    event ForSale(uint256 skuCount);

    event Sold(uint256 sku);

    event Shipped(uint256 sku);

    event Received(uint256 sku);

    //modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint256 _price) {
        require(msg.value >= _price);
        _;
    }

    modifier forSale(uint256 _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }

    modifier sold(uint256 _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    modifier shipped(uint256 _sku) {
        require(items[_sku].state == State.Shipped);
        _;
    }

    modifier received(uint256 _sku) {
        require(items[_sku].state == State.Received);
        _;
    }

    modifier checkValue(uint256 _sku) {
        _;
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        (bool success, ) = items[_sku].buyer.call{value: amountToRefund}("");
        require(success, "Transfer failed");
    }

    //note sku = skuCount in Item struct properties
    function addItem(uint256 _price, string memory _name) public onlyOwner {
        skuCount = skuCount.add(1);
        items[skuCount] = Item({
            sku: skuCount,
            price: _price,
            name: _name,
            state: State.ForSale,
            seller: payable(msg.sender),
            buyer: payable(address(0))
        });
        emit ForSale(skuCount);
    }

    function buyItem(uint256 sku)
        public
        payable
        forSale(sku)
        checkValue(sku)
        paidEnough(items[sku].price)
    {
        address buyer = msg.sender;
        uint256 price = items[sku].price;
        items[sku].buyer = payable(buyer);
        items[sku].state = State.Sold;
        (bool success, ) = items[sku].seller.call{value: price}("");
        require(success, "Transfer failed");
        emit Sold(sku);
    }

    function shipItem(uint256 sku)
        public
        sold(sku)
        verifyCaller(items[sku].seller)
    {
        items[sku].state = State.Shipped;
        emit Shipped(sku);
    }

    //This function should allow the seller to mark the item as recieved
    function receiveItem(uint256 sku)
        public
        shipped(sku)
        verifyCaller(items[sku].seller)
    {
        items[sku].state = State.Received;
        emit Received(sku);
    }

    // Do not need payable keyword when getting only
    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 price,
            uint256 sku,
            address seller,
            address buyer,
            string memory stateIs
        )
    {
        uint256 state;
        name = items[_sku].name;
        price = items[_sku].price;
        sku = items[_sku].sku;
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        state = uint256(items[_sku].state);
        if (state == 0) {
            stateIs = "For Sale";
        }
        if (state == 1) {
            stateIs = "Sold";
        }
    }
}
