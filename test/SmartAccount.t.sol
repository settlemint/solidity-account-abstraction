// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/SmartAccount.sol";
import "../contracts/SmartAccountFactory.sol";
import "../contracts/SmartEntryPoint.sol";

contract SmartAccountTest is Test {
    SmartAccount implementation;
    SmartAccountFactory factory;
    SmartEntryPoint entryPoint;
    address owner;
    address other;

    function setUp() public {
        owner = address(this);
        other = address(0x1);

        // Deploy EntryPoint
        entryPoint = new SmartEntryPoint();

        // Deploy Factory and Implementation
        factory = new SmartAccountFactory(entryPoint);
        implementation = SmartAccount(factory.accountImplementation());
    }

    function testAccountCreation() public {
        uint256 salt = 0;
        address accountAddress = address(factory.createAccount(owner, salt));
        SmartAccount account = SmartAccount(payable(accountAddress));

        // Verify owner
        assertEq(account.owner(), owner);

        // Verify creating same account returns existing one
        address sameAccount = address(factory.createAccount(owner, salt));
        assertEq(sameAccount, accountAddress);
    }

    function testAccountExecution() public {
        uint256 salt = 0;
        address accountAddress = address(factory.createAccount(owner, salt));
        SmartAccount account = SmartAccount(payable(accountAddress));

        // Fund the account
        vm.deal(address(account), 1 ether);
        assertEq(address(account).balance, 1 ether);

        // Test execution
        address target = other;
        uint256 value = 0.1 ether;
        bytes memory data = "";

        // Execute transaction
        account.execute(target, value, data);

        // Verify balance changes
        assertEq(target.balance, value);
        assertEq(address(account).balance, 0.9 ether);
    }

    function test_RevertWhen_NonOwnerExecutesTransaction() public {
        uint256 salt = 0;
        address accountAddress = address(factory.createAccount(owner, salt));
        SmartAccount account = SmartAccount(payable(accountAddress));

        // Try to execute as non-owner
        vm.prank(other);
        account.execute(other, 0, "");
    }

    function testGetAddress() public {
        uint256 salt = 0;
        address predictedAddress = factory.getAddress(owner, salt);
        address actualAddress = address(factory.createAccount(owner, salt));
        assertEq(predictedAddress, actualAddress);
    }

    receive() external payable { }
}
