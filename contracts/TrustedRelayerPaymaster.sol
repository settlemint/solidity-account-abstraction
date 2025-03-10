// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "account-abstraction/core/BasePaymaster.sol";

/**
 * @title TrustedRelayerPaymaster
 * @dev A simple paymaster that sponsors gas fees for transactions sent by trusted relayers
 * Implements the ERC-4337 BasePaymaster
 */
contract TrustedRelayerPaymaster is BasePaymaster {
    /// @notice Mapping to track trusted relayers
    mapping(address => bool) public trustedRelayers;

    /// @notice Event emitted when a relayer is added to trusted list
    /// @param relayer The address of the relayer
    event RelayerTrusted(address indexed relayer);

    /// @notice Event emitted when a relayer is removed from trusted list
    /// @param relayer The address of the relayer
    event RelayerUntrusted(address indexed relayer);

    /**
     * @dev Constructor
     * @param entryPoint_ The EntryPoint contract address
     */
    constructor(IEntryPoint entryPoint_) BasePaymaster(entryPoint_) {
        // BasePaymaster handles EntryPoint and Ownable initialization
    }

    /**
     * @notice Adds a relayer to the trusted list
     * @param relayer The relayer address to trust
     */
    function addTrustedRelayer(address relayer) external onlyOwner {
        require(relayer != address(0), "Invalid relayer address");
        require(!trustedRelayers[relayer], "Relayer already trusted");
        trustedRelayers[relayer] = true;
        emit RelayerTrusted(relayer);
    }

    /**
     * @notice Removes a relayer from the trusted list
     * @param relayer The relayer address to untrust
     */
    function removeTrustedRelayer(address relayer) external onlyOwner {
        require(trustedRelayers[relayer], "Relayer not trusted");
        trustedRelayers[relayer] = false;
        emit RelayerUntrusted(relayer);
    }

    /**
     * @dev Implementation of the validatePaymasterUserOp abstract method from BasePaymaster
     * @param userOp The user operation to validate
     * @param userOpHash The hash of the user operation
     * @param maxCost The maximum cost of the transaction
     * @return context Context to be passed to postOp
     * @return validationData Data used for signature validation
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
        (userOp, userOpHash); // Unused parameters

        // Get the transaction origin (the relayer)
        address relayer = tx.origin;

        // Check if the relayer is trusted
        require(trustedRelayers[relayer], "Relayer not trusted");

        // Make sure we have enough deposit to cover the transaction
        require(entryPoint.balanceOf(address(this)) >= maxCost, "Insufficient deposit");

        // Return the relayer address as context and successful validation (0)
        return (abi.encode(relayer), 0);
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
        // Extract the relayer from context
        address relayer = abi.decode(context, (address));

        // This is where you could implement more complex post-operation logic
        // For example, tracking usage per relayer, etc.

        // Suppress unused parameter warnings
        (mode, relayer, actualGasCost, actualUserOpFeePerGas);
    }
}
