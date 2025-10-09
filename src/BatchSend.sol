// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

using SafeERC20 for IERC20;

/// @title BatchSend
/// @notice Batch-sends ERC20 tokens to multiple recipients.
///         - Performs per-recipient transferFrom to avoid holding user funds and reduce calls.
///         - Enforces exact transfer amounts to reject fee-on-transfer tokens.
///         - Provides a permit-enabled variant to avoid a separate approval tx.
contract BatchSend is ReentrancyGuard {
    event TokensSent(address indexed token, address indexed sender, uint256 totalAmount, uint256 recipientCount);

    uint256 public constant MAX_RECIPIENTS = 1000;

    error ArrayLengthMismatch();
    error EmptyRecipients();
    error TooManyRecipients();
    error TransferFailed();
    error InexactTransfer();
    error InvalidRecipient();
    error InvalidAmount();
    error InvalidToken();
    error DuplicateRecipient();

    struct Transfer {
        address to;
        uint256 amount;
    }

    /// @notice Validates that recipients and amounts arrays are non-empty, of equal length,
    ///         contain no zero addresses, no zero amounts, and no duplicates.
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

    /// @notice Batch-send tokens from msg.sender to recipients.
    /// @dev Reverts if any transfer fails or if a token is fee-on-transfer (inexact delivery).
    function batchSend(address token, address[] calldata recipients, uint256[] calldata amounts)
        external
        nonReentrant
    {
        if (token == address(0)) revert InvalidToken();
        uint256 len = recipients.length;
        if (len == 0) revert EmptyRecipients();
        if (len != amounts.length) revert ArrayLengthMismatch();
        if (len > MAX_RECIPIENTS) revert TooManyRecipients();

        IERC20 t = IERC20(token);

        // Duplicate, zero address, and zero amount checks
        for (uint256 i = 0; i < len;) {
            address to = recipients[i];
            if (to == address(0)) revert InvalidRecipient();
            uint256 amount = amounts[i];
            if (amount == 0) revert InvalidAmount();

            for (uint256 j = i + 1; j < len;) {
                if (to == recipients[j]) revert DuplicateRecipient();
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < len;) {
            address to = recipients[i];
            uint256 amount = amounts[i];

            // Enforce exact delivery: revert on fee-on-transfer tokens
            uint256 beforeBal = t.balanceOf(to);
            bool ok = SafeERC20.trySafeTransferFrom(t, msg.sender, to, amount);
            if (!ok) revert TransferFailed();
            uint256 afterBal = t.balanceOf(to);
            if (afterBal < beforeBal) revert InexactTransfer();
            if (afterBal - beforeBal != amount) revert InexactTransfer();

            unchecked {
                totalAmount += amount;
                ++i;
            }
        }

        emit TokensSent(token, msg.sender, totalAmount, len);
    }

    /// @notice Batch-send tokens from a specified owner using EIP-2612 permit for approval.
    /// @dev Owner provides a signature permitting this contract to spend `value` until `deadline`.
    function batchSendWithPermit(
        address token,
        address owner,
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        if (token == address(0)) revert InvalidToken();
        uint256 len = recipients.length;
        if (len == 0) revert EmptyRecipients();
        if (len != amounts.length) revert ArrayLengthMismatch();
        if (len > MAX_RECIPIENTS) revert TooManyRecipients();

        IERC20 t = IERC20(token);

        // Approve this contract via permit
        IERC20Permit(token).permit(owner, address(this), value, deadline, v, r, s);

        // Duplicate, zero address, and zero amount checks
        for (uint256 i = 0; i < len;) {
            address to = recipients[i];
            if (to == address(0)) revert InvalidRecipient();
            uint256 amount = amounts[i];
            if (amount == 0) revert InvalidAmount();

            for (uint256 j = i + 1; j < len;) {
                if (to == recipients[j]) revert DuplicateRecipient();
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < len;) {
            address to = recipients[i];
            uint256 amount = amounts[i];

            // Enforce exact delivery: revert on fee-on-transfer tokens
            uint256 beforeBal = t.balanceOf(to);
            bool ok = SafeERC20.trySafeTransferFrom(t, owner, to, amount);
            if (!ok) revert TransferFailed();
            uint256 afterBal = t.balanceOf(to);
            if (afterBal < beforeBal) revert InexactTransfer();
            if (afterBal - beforeBal != amount) revert InexactTransfer();

            unchecked {
                totalAmount += amount;
                ++i;
            }
        }

        emit TokensSent(token, owner, totalAmount, len);
    }

    /// @notice Computes the sum of an array of amounts.
    function getTotalAmount(uint256[] calldata amounts) external pure returns (uint256) {
        uint256 len = amounts.length;
        uint256 total = 0;
        for (uint256 i = 0; i < len;) {
            unchecked {
                total += amounts[i];
                ++i;
            }
        }
        return total;
    }

    /// @notice Batch-send using a struct array to avoid parallel arrays.
    function batchSendStruct(address token, Transfer[] calldata transfers) external nonReentrant {
        if (token == address(0)) revert InvalidToken();
        uint256 len = transfers.length;
        if (len == 0) revert EmptyRecipients();
        if (len > MAX_RECIPIENTS) revert TooManyRecipients();
        IERC20 t = IERC20(token);

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < len;) {
            address to = transfers[i].to;
            uint256 amount = transfers[i].amount;
            if (to == address(0)) revert InvalidRecipient();
            if (amount == 0) revert InvalidAmount();
            // enforce exact delivery
            uint256 beforeBal = t.balanceOf(to);
            bool ok = SafeERC20.trySafeTransferFrom(t, msg.sender, to, amount);
            if (!ok) revert TransferFailed();
            uint256 afterBal = t.balanceOf(to);
            if (afterBal < beforeBal) revert InexactTransfer();
            if (afterBal - beforeBal != amount) revert InexactTransfer();
            unchecked {
                totalAmount += amount;
                ++i;
            }
        }

        emit TokensSent(token, msg.sender, totalAmount, len);
    }
}
