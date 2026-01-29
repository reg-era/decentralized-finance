// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Oracle.sol";
import "./Stablecoin.sol";
import "./Tokens.sol";

contract LendingPlatform {
    Stable public stable;
    Volatile public volatileToken;
    lStable public lstable;
    lVolatile public lvolatile;
    Oracle public oracle;

    uint256 constant COLLATERAL_RATIO = 150; // 150%
    uint256 constant LIQUIDATION_BONUS = 10; // 10%

    mapping(address => uint256) public stableDebt;

    constructor(
        address _stable,
        address _volatile,
        address _lstable,
        address _lvolatile
    ) {
        stable = Stable(_stable);
        volatileToken = Volatile(_volatile);
        lstable = lStable(_lstable);
        lvolatile = lVolatile(_lvolatile);
    }

    function registerOracle(address _oracle) external {
        oracle = Oracle(_oracle);
    }

    function depositStable(uint256 amount) external {
        require(amount > 0, "Invalid amount");

        stable.transferFrom(msg.sender, address(this), amount);
        lstable.mint(msg.sender, amount);
    }

    function depositVolatile(uint256 amount) external {
        require(amount > 0, "Invalid amount");

        volatileToken.transferFrom(msg.sender, address(this), amount);
        lvolatile.mint(msg.sender, amount);
    }

    function borrowStable(uint256 amount) external {
        require(amount > 0, "Invalid amount");

        uint256 price = oracle.getEthPrice();

        uint256 collateralValue = (lvolatile.balanceOf(msg.sender) * price) /
            1e18;

        uint256 newDebt = stableDebt[msg.sender] + amount;

        require(
            collateralValue * 100 >= newDebt * COLLATERAL_RATIO,
            "Insufficient collateral"
        );

        stableDebt[msg.sender] = newDebt;
        stable.mint(msg.sender, amount);
    }

    function liquidate(address user) external {
        uint256 price = oracle.getEthPrice();

        uint256 collateralValue = (lvolatile.balanceOf(user) * price) / 1e18;

        uint256 debt = stableDebt[user];

        require(debt > 0, "No debt");
        require(
            collateralValue * 100 < debt * COLLATERAL_RATIO,
            "Position healthy"
        );

        uint256 repayAmount = (debt * 110) / 100;

        stable.transferFrom(msg.sender, address(this), repayAmount);
        stable.burn(address(this), debt);

        uint256 collateral = lvolatile.balanceOf(user);

        stableDebt[user] = 0;
        lvolatile.burn(user, collateral);
        volatileToken.transfer(msg.sender, collateral);
    }
}
