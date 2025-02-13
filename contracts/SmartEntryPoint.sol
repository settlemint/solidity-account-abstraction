// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "account-abstraction/core/EntryPoint.sol";

/**
 * @title SmartEntryPoint
 * @dev Custom EntryPoint implementation for our Smart Account system
 * Uses the standard ERC-4337 EntryPoint
 */
contract SmartEntryPoint is EntryPoint {
    /// @notice Creates a new EntryPoint
    constructor() EntryPoint() { }
}
