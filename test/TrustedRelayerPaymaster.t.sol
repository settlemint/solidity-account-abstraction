// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/TrustedRelayerPaymaster.sol";
import "../contracts/SmartEntryPoint.sol";
import "account-abstraction/interfaces/PackedUserOperation.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrustedRelayerPaymasterTest is Test {
    TrustedRelayerPaymaster paymaster;
    SmartEntryPoint entryPoint;
    address owner;
    address relayer;
    address user;

    function setUp() public {
        owner = address(this);
        relayer = address(0x1);
        user = address(0x2);

        // Deploy EntryPoint
        entryPoint = new SmartEntryPoint();

        // Deploy Paymaster
        paymaster = new TrustedRelayerPaymaster(entryPoint);

        // Fund paymaster
        vm.deal(address(paymaster), 100 ether);
        paymaster.deposit{ value: 100 ether }();
    }

    function testAddTrustedRelayer() public {
        paymaster.addTrustedRelayer(relayer);
        assertTrue(paymaster.trustedRelayers(relayer));
    }

    function testRemoveTrustedRelayer() public {
        paymaster.addTrustedRelayer(relayer);
        assertTrue(paymaster.trustedRelayers(relayer));

        paymaster.removeTrustedRelayer(relayer);
        assertFalse(paymaster.trustedRelayers(relayer));
    }

    function test_RevertWhen_AddingZeroAddressRelayer() public {
        vm.prank(owner);
        vm.expectRevert("Invalid relayer address");
        paymaster.addTrustedRelayer(address(0));
    }

    function test_RevertWhen_AddingExistingRelayer() public {
        paymaster.addTrustedRelayer(relayer);
        vm.expectRevert("Relayer already trusted");
        paymaster.addTrustedRelayer(relayer);
    }

    function test_RevertWhen_RemovingNonExistentRelayer() public {
        vm.expectRevert("Relayer not trusted");
        paymaster.removeTrustedRelayer(relayer);
    }

    function test_RevertWhen_NonOwnerAddsRelayer() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        paymaster.addTrustedRelayer(relayer);
    }

    function test_RevertWhen_NonOwnerRemovesRelayer() public {
        paymaster.addTrustedRelayer(relayer);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        paymaster.removeTrustedRelayer(relayer);
    }

    function testDeposit() public {
        uint256 initialBalance = entryPoint.balanceOf(address(paymaster));
        uint256 depositAmount = 1 ether;

        vm.deal(address(this), depositAmount);
        paymaster.deposit{ value: depositAmount }();

        uint256 newBalance = entryPoint.balanceOf(address(paymaster));
        assertEq(newBalance, initialBalance + depositAmount);
    }

    function testWithdraw() public {
        uint256 withdrawAmount = 1 ether;
        uint256 initialBalance = address(owner).balance;

        paymaster.withdrawTo(payable(owner), withdrawAmount);

        uint256 newBalance = address(owner).balance;
        assertEq(newBalance, initialBalance + withdrawAmount);
    }

    function testValidatePaymasterUserOp() public {
        // Add relayer to trusted list
        paymaster.addTrustedRelayer(relayer);

        // Create a valid user operation
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: user,
            nonce: 0,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(uint256(100_000 << 128) | uint256(100_000)),
            preVerificationGas: 100_000,
            gasFees: bytes32(uint256(100 << 128) | uint256(10)),
            paymasterAndData: abi.encodePacked(address(paymaster), uint128(100_000), uint128(100_000), abi.encode(relayer)),
            signature: ""
        });

        bytes32 userOpHash = keccak256(abi.encode(userOp));
        uint256 maxCost = 100_000 * 100;

        // Set tx.origin and msg.sender
        vm.startPrank(address(entryPoint), relayer);

        (bytes memory context, uint256 validationData) = paymaster.validatePaymasterUserOp(userOp, userOpHash, maxCost);

        // Verify validation succeeded
        assertEq(validationData, 0);
        assertEq(abi.decode(context, (address)), relayer);

        vm.stopPrank();
    }

    function test_RevertWhen_ValidatingWithUntrustedRelayer() public {
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: user,
            nonce: 0,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(uint256(100_000 << 128) | uint256(100_000)),
            preVerificationGas: 100_000,
            gasFees: bytes32(uint256(100 << 128) | uint256(10)),
            paymasterAndData: abi.encodePacked(address(paymaster), uint128(100_000), uint128(100_000), abi.encode(relayer)),
            signature: ""
        });

        bytes32 userOpHash = keccak256(abi.encode(userOp));
        uint256 maxCost = 100_000 * 100;

        // Set tx.origin and msg.sender
        vm.startPrank(address(entryPoint), relayer);

        vm.expectRevert(abi.encodeWithSelector(TrustedRelayerPaymaster.RelayerNotTrusted.selector, relayer));
        paymaster.validatePaymasterUserOp(userOp, userOpHash, maxCost);

        vm.stopPrank();
    }

    function test_RevertWhen_ValidatingWithInvalidData() public {
        paymaster.addTrustedRelayer(relayer);

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: user,
            nonce: 0,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(uint256(100_000 << 128) | uint256(100_000)),
            preVerificationGas: 100_000,
            gasFees: bytes32(uint256(100 << 128) | uint256(10)),
            paymasterAndData: abi.encodePacked(address(paymaster), uint128(100_000), uint128(100_000)),
            signature: ""
        });

        bytes32 userOpHash = keccak256(abi.encode(userOp));
        uint256 maxCost = 100_000 * 100;

        // Set tx.origin and msg.sender
        vm.startPrank(address(entryPoint), relayer);

        vm.expectRevert(TrustedRelayerPaymaster.InvalidPaymasterData.selector);
        paymaster.validatePaymasterUserOp(userOp, userOpHash, maxCost);

        vm.stopPrank();
    }

    receive() external payable { }
}
