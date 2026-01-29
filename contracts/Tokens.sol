// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Mintable.sol";

contract Stable is MintableERC20 {
    constructor() MintableERC20("Stable", "STB") {}
}

contract Volatile is MintableERC20 {
    constructor() MintableERC20("Volatile", "VOL") {}
}

contract lStable is MintableERC20 {
    constructor() MintableERC20("Lending Stable", "lSTB") {}
}

contract lVolatile is MintableERC20 {
    constructor() MintableERC20("Lending Volatile", "lVOL") {}
}
