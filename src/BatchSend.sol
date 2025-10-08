// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

contract BatchSend {
    event TokensSent(address indexed token, address indexed sender, uint256 totalAmount, uint256 recipientCount);

    error ArrayLengthMismatch();
    error TransferFailed();
    error InvalidRecipient();
    error InvalidAmount();

    function validate(address[] calldata recipients, uint256[] calldata amounts) public pure returns (bool) {
        if (recipients.length == 0) return false;
        if (recipients.length != amounts.length) return false;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) return false;
            if (amounts[i] == 0) return false;

            for (uint256 j = i + 1; j < recipients.length; j++) {
                if (recipients[i] == recipients[j]) return false;
            }
        }

        return true;
    }

    function batchSend(address token, address[] calldata recipients, uint256[] calldata amounts) external {
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < amounts.length; i++) {
            if (recipients[i] == address(0)) revert InvalidRecipient();
            if (amounts[i] == 0) revert InvalidAmount();
            totalAmount += amounts[i];
        }

        bool pulled = SafeERC20.trySafeTransferFrom(IERC20(token), msg.sender, address(this), totalAmount);
        if (!pulled) revert TransferFailed();

        for (uint256 i = 0; i < recipients.length; i++) {
            bool sent = SafeERC20.trySafeTransfer(IERC20(token), recipients[i], amounts[i]);
            if (!sent) revert TransferFailed();
        }

        emit TokensSent(token, msg.sender, totalAmount, recipients.length);
    }

    function getTotalAmount(uint256[] calldata amounts) external pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
}
