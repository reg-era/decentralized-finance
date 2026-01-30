// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Oracle {
    uint256 private price; // Volatile priced in Stable (18 decimals)
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getEthPrice() external view returns (uint256) {
        return price;
    }

    function setEthPrice(uint256 newPrice) external {
        require(newPrice > 0, "Invalid price");
        require(msg.sender == owner, "Not authorized");
        price = newPrice;
    }
}
