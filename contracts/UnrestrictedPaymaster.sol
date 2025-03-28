// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "account-abstraction/core/BasePaymaster.sol";

/**
 * @title UnrestrictedPaymaster
 * @dev A simple paymaster that accepts all transactions without any validation
 * This is specifically designed for testing purposes and should not be used in production
 * Implements the ERC-4337 BasePaymaster
 */
contract UnrestrictedPaymaster is BasePaymaster {
    /// @notice Error thrown when there is insufficient deposit
    error InsufficientDeposit();

    /**
     * @dev Constructor
     * @param entryPoint_ The EntryPoint contract address
     */
    constructor(IEntryPoint entryPoint_) BasePaymaster(entryPoint_) {
        // BasePaymaster handles EntryPoint and Ownable initialization
    }

    /**
     * @dev Implementation of the validatePaymasterUserOp abstract method from BasePaymaster
     * @param userOp The user operation to validate
     * @param userOpHash The hash of the user operation
     * @param maxCost The maximum cost of the transaction
     * @return context Empty context since we don't need any
     * @return validationData Always returns 0 to indicate success
     */
    // solidity-ignore-next-line func-mutability
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    )
        internal
        override
        returns (bytes memory context, uint256 validationData)
    {
        // Check if we have enough deposit
        uint256 currentDeposit = entryPoint.balanceOf(address(this));
        if (currentDeposit < maxCost) {
            revert InsufficientDeposit();
        }

        // Accept all transactions by returning empty context and 0 validation data
        return ("", 0);
    }

    /**
     * @dev Override the _postOp method to handle post-operation logic
     * This is called automatically by BasePaymaster's final postOp implementation
     */
    // solidity-ignore-next-line func-mutability
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    )
        internal
        override
    {
        // No post-op logic needed since we accept all transactions
    }
}
