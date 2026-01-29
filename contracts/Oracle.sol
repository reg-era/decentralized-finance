// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract oracle {
    uint256 private ethPrice;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getEthPrice() external view returns (uint256) {
        return ethPrice;
    }

    function setEthPrice(uint256 newPrice) public {
        require(msg.sender == owner, "Not authorized");
        ethPrice = newPrice;
    }
}