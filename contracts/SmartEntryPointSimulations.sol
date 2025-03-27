// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "account-abstraction/core/EntryPointSimulations.sol";

/**
 * @title SmartEntryPointSimulations
 * @dev Simulation contract for testing UserOperations without actual execution
 * This contract should never be deployed on-chain and is only used as a parameter for "eth_call" requests.
 */
contract SmartEntryPointSimulations is EntryPointSimulations {
    /**
     * @notice Simulation contract should not be deployed
     * Accounts should not trust it as an entrypoint, since the simulation functions don't verify signatures
     */
    constructor() EntryPointSimulations() { }
}
