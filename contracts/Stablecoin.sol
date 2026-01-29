// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Oracle.sol";

contract StableCoin is ERC20 {
    Oracle public oracle;

    mapping(address => uint256) public ethDeposits;
    mapping(address => uint256) public debt;

    constructor() ERC20("StableCoin", "SBC") {}

    // ORACLE
    function registerOracle(address oracleAddress) public {
        oracle = Oracle(oracleAddress);
    }

    // COLLATERAL
    function deposit() public payable {
        require(msg.value > 0, "No ETH sent");
        ethDeposits[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(ethDeposits[msg.sender] >= amount, "Insufficient collateral");

        ethDeposits[msg.sender] -= amount;

        // ensure position is still healthy
        require(_isHealthy(msg.sender), "Would break collateral ratio");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send ETH");
    }

    // MINT / BURN
    function mint(uint256 amount) public {
        require(amount > 0, "Invalid amount");

        debt[msg.sender] += amount;
        require(_isHealthy(msg.sender), "Exceeds mint limit");

        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        require(debt[msg.sender] >= amount, "Too much burn");

        debt[msg.sender] -= amount;
        _burn(msg.sender, amount);
    }

    // LIQUIDATION
    function liquidate(address user) public {
        require(!_isHealthy(user), "Position is healthy");

        uint256 userDebt = debt[user];
        require(userDebt > 0, "No debt");

        // liquidator must pay debt in SBC
        _burn(msg.sender, userDebt);

        uint256 collateral = ethDeposits[user];
        uint256 reward = (collateral * 80) / 100;

        // wipe position
        debt[user] = 0;
        ethDeposits[user] = 0;

        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "Failed to send ETH");
    }

    // INTERNAL
    function _isHealthy(address user) internal view returns (bool) {
        uint256 ethPrice = oracle.getEthPrice(); // USD 18 decimals

        uint256 collateralValue =
            (ethDeposits[user] * ethPrice) / 1e18;

        // must be >= 2x debt
        return collateralValue >= debt[user] * 2;
    }
}
