// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MockToken} from "../src/MockToken.sol";
import {BatchSend} from "../src/BatchSend.sol";
import {FeeOnTransferToken} from "../src/mocks/FeeOnTransferToken.sol";
import {RevertOnZeroToken} from "../src/mocks/RevertOnZeroToken.sol";
import {PermitMockToken} from "../src/mocks/PermitMockToken.sol";

contract BatchSendTest is Test {
    MockToken public token;
    BatchSend public batchSend;

    address public owner;
    address public user1;
    address public user2;
    address public user3;

    uint256 constant INITIAL_SUPPLY = 1_000 * 10 ** 18;
    uint256 constant TRANSFER_AMOUNT = 100 * 10 ** 18;

    event TokensSent(address indexed token, address indexed sender, uint256 totalAmount, uint256 recipientCount);

    function setUp() public {
        // Create test accounts
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy contracts
        token = new MockToken();
        batchSend = new BatchSend();

        // Verify initial state
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                            UNIT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MockToken_Deployment() public view {
        assertEq(token.name(), "Mock Token");
        assertEq(token.symbol(), "MTK");
        assertEq(token.decimals(), 18);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    function test_MockToken_Mint() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function test_BatchSend_Deployment() public view {
        assertTrue(address(batchSend) != address(0));
    }

    function test_Validate_ValidInput() public view {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        assertTrue(batchSend.validate(recipients, amounts));
    }

    function test_Validate_EmptyArrays() public view {
        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        assertFalse(batchSend.validate(recipients, amounts));
    }

    function test_Validate_MismatchedLengths() public view {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        assertFalse(batchSend.validate(recipients, amounts));
    }

    function test_Validate_ZeroAddress() public view {
        address[] memory recipients = new address[](2);
        recipients[0] = address(0);
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        assertFalse(batchSend.validate(recipients, amounts));
    }

    function test_Validate_ZeroAmount() public view {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0;
        amounts[1] = 200;

        assertFalse(batchSend.validate(recipients, amounts));
    }

    function test_Validate_DuplicateRecipients() public view {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        assertFalse(batchSend.validate(recipients, amounts));
    }

    function test_GetTotalAmount() public view {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;

        uint256 total = batchSend.getTotalAmount(amounts);
        assertEq(total, 600);
    }

    function test_BatchSend_RevertsOnRevertOnZeroToken() public {
        // Deploy the special token
        RevertOnZeroToken revertToken = new RevertOnZeroToken();
        vm.deal(address(revertToken), 100 ether); // Give the token contract ether if needed

        // If RevertOnZeroToken inherits from ERC20, try casting to the parent with mint
        MockToken(address(revertToken)).mint(address(this), 100 ether);

        // Prepare recipients and amounts (one of them is zero)
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 ether;
        amounts[1] = 0; // This should trigger revert in the token

        revertToken.approve(address(batchSend), 10 ether);

        // Expect revert from BatchSend.InvalidAmount (since batchSend checks for zero amount)
        vm.expectRevert(BatchSend.InvalidAmount.selector);
        batchSend.batchSend(address(revertToken), recipients, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_BatchSend_SingleRecipient() public {
        // Setup
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TRANSFER_AMOUNT;

        // Approve BatchSend contract
        token.approve(address(batchSend), TRANSFER_AMOUNT);

        // Record balances before
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 user1BalanceBefore = token.balanceOf(user1);

        // Expect event
        vm.expectEmit(true, true, false, true);
        emit TokensSent(address(token), owner, TRANSFER_AMOUNT, 1);

        // Execute batch send
        batchSend.batchSend(address(token), recipients, amounts);

        // Verify balances
        assertEq(token.balanceOf(owner), ownerBalanceBefore - TRANSFER_AMOUNT);
        assertEq(token.balanceOf(user1), user1BalanceBefore + TRANSFER_AMOUNT);
    }

    function test_BatchSend_MultipleRecipients() public {
        // Setup
        address[] memory recipients = new address[](3);
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = user3;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10 ** 18;
        amounts[1] = 200 * 10 ** 18;
        amounts[2] = 300 * 10 ** 18;

        uint256 totalAmount = 600 * 10 ** 18;

        // Approve
        token.approve(address(batchSend), totalAmount);

        // Record balances
        uint256 ownerBalanceBefore = token.balanceOf(owner);

        // Execute
        batchSend.batchSend(address(token), recipients, amounts);

        // Verify
        assertEq(token.balanceOf(owner), ownerBalanceBefore - totalAmount);
        assertEq(token.balanceOf(user1), 100 * 10 ** 18);
        assertEq(token.balanceOf(user2), 200 * 10 ** 18);
        assertEq(token.balanceOf(user3), 300 * 10 ** 18);
    }

    function test_BatchSend_RevertsOnArrayLengthMismatch() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.expectRevert(BatchSend.ArrayLengthMismatch.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_RevertsOnZeroAddress() public {
        address[] memory recipients = new address[](1);
        recipients[0] = address(0);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        token.approve(address(batchSend), 100);

        vm.expectRevert(BatchSend.InvalidRecipient.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_RevertsOnZeroTokenAddress() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.expectRevert(BatchSend.InvalidToken.selector);
        batchSend.batchSend(address(0), recipients, amounts);
    }

    function test_BatchSend_RevertsOnEmptyRecipients() public {
        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.expectRevert(BatchSend.EmptyRecipients.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_RevertsOnDuplicateRecipients() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user1;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        token.approve(address(batchSend), 3);
        vm.expectRevert(BatchSend.DuplicateRecipient.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_RevertsOnZeroAmount() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;

        vm.expectRevert(BatchSend.InvalidAmount.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_RevertsOnInsufficientApproval() public {
        address[] memory recipients = new address[](1);
        recipients[0] = user1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TRANSFER_AMOUNT;

        // Don't approve or approve insufficient amount
        token.approve(address(batchSend), TRANSFER_AMOUNT - 1);

        vm.expectRevert(BatchSend.TransferFailed.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_RevertsOnInsufficientBalance() public {
        // Transfer away all tokens except 50
        assertTrue(token.transfer(user1, INITIAL_SUPPLY - 50 * 10 ** 18));

        address[] memory recipients = new address[](1);
        recipients[0] = user2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = TRANSFER_AMOUNT;

        token.approve(address(batchSend), TRANSFER_AMOUNT);

        vm.expectRevert(BatchSend.TransferFailed.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_LargeNumberOfRecipients() public {
        uint256 recipientCount = 100;
        address[] memory recipients = new address[](recipientCount);
        uint256[] memory amounts = new uint256[](recipientCount);

        uint256 amountPerRecipient = 10 * 10 ** 18;
        uint256 totalAmount = amountPerRecipient * recipientCount;

        // Setup recipients and amounts
        for (uint256 i = 0; i < recipientCount; i++) {
            recipients[i] = address(uint160(i + 1000));
            amounts[i] = amountPerRecipient;
        }

        // Approve
        token.approve(address(batchSend), totalAmount);

        // Execute
        batchSend.batchSend(address(token), recipients, amounts);

        // Verify each recipient got correct amount
        for (uint256 i = 0; i < recipientCount; i++) {
            assertEq(token.balanceOf(recipients[i]), amountPerRecipient);
        }
    }

    function test_BatchSend_EmitsCorrectEvent() public {
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 * 10 ** 18;
        amounts[1] = 200 * 10 ** 18;

        uint256 totalAmount = 300 * 10 ** 18;

        token.approve(address(batchSend), totalAmount);

        // Expect event with exact parameters
        vm.expectEmit(true, true, false, true);
        emit TokensSent(address(token), owner, totalAmount, 2);

        batchSend.batchSend(address(token), recipients, amounts);
    }

    function test_BatchSend_RevertsOnFeeOnTransferToken() public {
        FeeOnTransferToken feeToken = new FeeOnTransferToken();
        // Approve a total for 2 transfers
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 50 ether;
        feeToken.approve(address(batchSend), 150 ether);

        vm.expectRevert(BatchSend.InexactTransfer.selector);
        batchSend.batchSend(address(feeToken), recipients, amounts);
    }

    function test_BatchSend_StructVariant() public {
        MockToken t = new MockToken();
        // prepare transfers
        BatchSend.Transfer[] memory transfers = new BatchSend.Transfer[](3);
        transfers[0] = BatchSend.Transfer({to: user1, amount: 1 ether});
        transfers[1] = BatchSend.Transfer({to: user2, amount: 2 ether});
        transfers[2] = BatchSend.Transfer({to: user3, amount: 3 ether});

        t.approve(address(batchSend), 6 ether);
        uint256 ownerBefore = t.balanceOf(address(this));
        batchSend.batchSendStruct(address(t), transfers);
        assertEq(t.balanceOf(address(this)), ownerBefore - 6 ether);
        assertEq(t.balanceOf(user1), 1 ether);
        assertEq(t.balanceOf(user2), 2 ether);
        assertEq(t.balanceOf(user3), 3 ether);
    }

    function test_BatchSend_RevertsOnTooManyRecipients() public {
        uint256 count = 1001; // exceeds MAX_RECIPIENTS = 1000
        address[] memory recipients = new address[](count);
        uint256[] memory amounts = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            recipients[i] = address(uint160(i + 1));
            amounts[i] = 1;
        }
        token.approve(address(batchSend), count);
        vm.expectRevert(BatchSend.TooManyRecipients.selector);
        batchSend.batchSend(address(token), recipients, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                            PERMIT TEST
    //////////////////////////////////////////////////////////////*/

    function test_BatchSendWithPermit_Success() public {
        // Prepare a permit-enabled token and owner with private key
        (address permitOwner, uint256 permitPriv) = makeAddrAndKey("permitOwner");
        PermitMockToken pmt = new PermitMockToken();
        pmt.mint(permitOwner, 1000 ether);

        // Recipients
        address[] memory recipients = new address[](2);
        recipients[0] = user1;
        recipients[1] = user2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 ether;
        amounts[1] = 20 ether;
        uint256 totalAmount = 30 ether;

        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = pmt.nonces(permitOwner);
        bytes32 permitTypeHash =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        bytes32 structHash =
            keccak256(abi.encode(permitTypeHash, permitOwner, address(batchSend), totalAmount, nonce, deadline));
        bytes32 domainSeparator = pmt.DOMAIN_SEPARATOR();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(permitPriv, digest);

        uint256 ownerBefore = pmt.balanceOf(permitOwner);
        batchSend.batchSendWithPermit(address(pmt), permitOwner, recipients, amounts, totalAmount, deadline, v, r, s);
        assertEq(pmt.balanceOf(permitOwner), ownerBefore - totalAmount);
        assertEq(pmt.balanceOf(user1), 10 ether);
        assertEq(pmt.balanceOf(user2), 20 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_BatchSend(uint8 recipientCount, uint256 amount) public {
        // Bound inputs
        recipientCount = uint8(bound(recipientCount, 1, 50));
        amount = bound(amount, 1, INITIAL_SUPPLY / recipientCount);

        address[] memory recipients = new address[](recipientCount);
        uint256[] memory amounts = new uint256[](recipientCount);

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < recipientCount; i++) {
            recipients[i] = address(uint160(i + 1));
            amounts[i] = amount;
            totalAmount += amount;
        }

        token.approve(address(batchSend), totalAmount);

        uint256 ownerBalanceBefore = token.balanceOf(owner);

        batchSend.batchSend(address(token), recipients, amounts);

        assertEq(token.balanceOf(owner), ownerBalanceBefore - totalAmount);

        for (uint256 i = 0; i < recipientCount; i++) {
            assertEq(token.balanceOf(recipients[i]), amount);
        }
    }

    function testFuzz_GetTotalAmount(uint256[] memory amounts) public view {
        vm.assume(amounts.length > 0 && amounts.length < 100);

        uint256 expectedTotal = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = bound(amounts[i], 0, type(uint128).max);
            expectedTotal += amounts[i];
        }

        uint256 actualTotal = batchSend.getTotalAmount(amounts);
        assertEq(actualTotal, expectedTotal);
    }
}
