// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "account-abstraction/core/BaseAccount.sol";
import "account-abstraction/core/Helpers.sol";
import "account-abstraction/accounts/callback/TokenCallbackHandler.sol";

/**
 * @title SmartAccount
 * @dev Implementation of a simple ERC-4337 Account with ECDSA validation.
 * Supports upgrades through UUPS proxy pattern and handles token callbacks.
 */
contract SmartAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;

    /// @notice The owner's address (signer that can execute transactions)
    address public owner;

    /// @notice The EntryPoint contract - the ERC-4337 singleton that executes UserOperations
    IEntryPoint private immutable _entryPoint;

    /// @notice Emitted when the account is initialized with an owner
    /// @param entryPoint The EntryPoint contract being used
    /// @param owner The account owner
    event SmartAccountInitialized(IEntryPoint indexed entryPoint, address indexed owner);

    /// @notice Emitted when a transaction is executed through this account
    /// @param target The destination address for the transaction
    /// @param value The amount of ETH sent
    /// @param data The calldata sent to the target
    event TransactionExecuted(address indexed target, uint256 value, bytes data);

    /// @notice Ensures only the owner or the account itself can call a function
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @notice Creates a new account implementation
    /// @param anEntryPoint The EntryPoint contract to use
    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /// @notice Validates that the caller is either the owner or the account itself
    function _onlyOwner() internal view {
        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }

    /// @notice Executes a transaction from this account
    /// @param dest The destination address for the transaction
    /// @param value The amount of ETH to send
    /// @param func The calldata for the transaction
    function execute(address dest, uint256 value, bytes calldata func) external override {
        _requireForExecute();
        _call(dest, value, func);
        emit TransactionExecuted(dest, value, func);
    }

    /// @notice Initializes the account with an owner - can only be called once
    /// @param anOwner The owner's address
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        emit SmartAccountInitialized(_entryPoint, owner);
    }

    /// @inheritdoc BaseAccount
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        // UserOpHash can be generated using eth_signTypedData_v4
        if (owner != ECDSA.recover(userOpHash, userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    /// @notice Ensures the caller is either the EntryPoint or the owner
    function _requireForExecute() internal view virtual override {
        require(msg.sender == address(entryPoint()) || msg.sender == owner, "account: not Owner or EntryPoint");
    }

    /// @notice Makes the actual call to the destination contract
    /// @param target The address to call
    /// @param value The amount of ETH to send
    /// @param data The calldata to send
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{ value: value }(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _onlyOwner();
    }

    /// @notice Required for receiving ETH
    receive() external payable { }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{ value: msg.value }(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }
}
