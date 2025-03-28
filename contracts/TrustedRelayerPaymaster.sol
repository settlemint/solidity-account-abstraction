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

    /// @notice Error thrown when relayer is not trusted
    error RelayerNotTrusted(address relayer);

    /// @notice Error thrown when paymasterAndData format is invalid
    error InvalidPaymasterData();

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
        bytes calldata paymasterAndData = userOp.paymasterAndData;

        // paymasterAndData is encoded as follows:
        // [paymaster address (20 bytes)][verificationGas (16 bytes)][postOpGas (16 bytes)][encoded address (min 20)]
        // @see
        // https://github.com/wevm/viem/blob/7f7706edefb97948233d61a0626f4b1069b455e4/src/account-abstraction/utils/userOperation/toPackedUserOperation.ts#L39
        if (paymasterAndData.length < 20 + 16 + 16 + 20) {
            revert InvalidPaymasterData();
        }

        // Skip paymaster address (20 bytes) + verification gas limit (16 bytes) + post op gas limit (16 bytes)
        bytes calldata paymasterData = paymasterAndData[20 + 16 + 16:];
        address dataRelayer = abi.decode(paymasterData, (address));

        // Verify tx.origin matches dataRelayer in non-simulation context
        if (tx.origin != address(0)) {
            if (tx.origin != dataRelayer) {
                revert InvalidPaymasterData();
            }
        }

        if (!trustedRelayers[dataRelayer]) {
            revert RelayerNotTrusted(dataRelayer);
        }

        // Check deposit
        uint256 currentDeposit = entryPoint.balanceOf(address(this));

        if (currentDeposit < maxCost) {
            revert("Insufficient deposit");
        }

        // Return the relayer as context
        return (abi.encode(dataRelayer), 0);
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
        // Handle different post-op modes
        if (mode == PostOpMode.opSucceeded) { } else if (mode == PostOpMode.opReverted) { } else { }
    }
}
