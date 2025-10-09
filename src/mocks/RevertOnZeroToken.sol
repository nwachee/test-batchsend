// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RevertOnZeroToken is ERC20 {
    constructor() ERC20("ZeroRevert", "ZRV") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) {
            require(value != 0, "ZERO_TRANSFER");
        }
        super._update(from, to, value);
    }

    // In RevertOnZeroToken.sol
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
