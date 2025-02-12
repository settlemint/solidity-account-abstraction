// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-community/contracts/account/Account.sol";
import "@openzeppelin/contracts-community/contracts/account/AccountCore.sol";

contract SmartAccount is AccountCore, Account, Initializable, ReentrancyGuard {
    using ECDSA for bytes32;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TransactionExecuted(address indexed target, uint256 value, bytes data);

    constructor() EIP712("SmartAccount", "1") { }

    function initialize(address owner) public initializer {
        _setSigner(owner);
    }

    function _rawSignatureValidation(
        bytes32 hash,
        bytes calldata signature
    )
        internal
        view
        virtual
        override
        returns (bool)
    {
        address recovered = hash.recover(signature);
        return recovered == owner();
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data
    )
        external
        onlyOwner
        nonReentrant
        returns (bytes memory)
    {
        (bool success, bytes memory result) = target.call{ value: value }(data);
        require(success, "Transaction failed");

        emit TransactionExecuted(target, value, data);
        return result;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        address oldOwner = owner();
        _setSigner(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    receive() external payable { }

    function executeERC20Transfer(address token, address to, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(to, amount), "Token transfer failed");
    }

    function executeERC20Approve(address token, address spender, uint256 amount) external onlyOwner {
        require(IERC20(token).approve(spender, amount), "Token approval failed");
    }
}
