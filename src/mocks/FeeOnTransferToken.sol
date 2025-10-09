// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Simple fee-on-transfer token: charges a fixed percentage fee that is burned.
contract FeeOnTransferToken is ERC20 {
    uint256 public constant FEE_BPS = 500; // 5%

    constructor() ERC20("Fee Token", "FEE") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from == address(0) || to == address(0)) {
            // mint or burn path, no fee
            super._update(from, to, value);
            return;
        }
        uint256 fee = (value * FEE_BPS) / 10_000;
        uint256 received = value - fee;
        super._update(from, to, received);
        if (fee > 0) {
            // burn fee from sender
            super._update(from, address(0), fee);
        }
    }
}
