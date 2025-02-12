// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin-contracts/utils/Create2.sol";
import "./SmartAccount.sol";

contract SmartAccountFactory {
    event AccountCreated(address indexed account, address indexed owner);

    address private immutable _implementation;

    constructor() {
        _implementation = address(new SmartAccount());
    }

    function createAccount(address owner, uint256 salt) external returns (address) {
        bytes32 saltBytes = bytes32(salt);
        address addr = getAddress(owner, saltBytes);

        if (addr.code.length > 0) {
            return addr;
        }

        SmartAccount account = new SmartAccount{ salt: saltBytes }();
        account.initialize(owner);

        emit AccountCreated(address(account), owner);
        return address(account);
    }

    function getAddress(address owner, bytes32 salt) public view returns (address) {
        bytes memory bytecode = type(SmartAccount).creationCode;
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        return address(uint160(uint256(hash)));
    }
}
