// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FlakyToken is ERC20 {
    uint256 public remainingSuccesses;

    constructor(uint256 _remainingSuccesses) ERC20("Flaky", "FLK") {
        remainingSuccesses = _remainingSuccesses;
        _mint(msg.sender, 1_000_000 ether);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0) && to != address(0)) {
            if (remainingSuccesses == 0) revert("FLAKY_FAIL");
            unchecked {
                remainingSuccesses--;
            }
        }
        super._update(from, to, value);
    }
}
