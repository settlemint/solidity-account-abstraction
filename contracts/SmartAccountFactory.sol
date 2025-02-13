// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./SmartAccount.sol";
import "./SmartEntryPoint.sol";

/**
 * @title SmartAccountFactory
 * @dev Factory contract for deploying SmartAccount proxies using CREATE2 for deterministic addresses
 * Each account is deployed as a proxy pointing to a shared implementation
 */
contract SmartAccountFactory {
    /// @notice The implementation contract that all proxies will point to
    SmartAccount public immutable accountImplementation;
    /// @notice The EntryPoint contract that all accounts will use
    IEntryPoint public immutable entryPoint;

    /// @notice Emitted when a new account is created
    /// @param account The address of the created account
    /// @param owner The owner of the created account
    event AccountCreated(address indexed account, address indexed owner);

    /// @notice Creates the factory and deploys the implementation contract
    /// @param _entryPoint The EntryPoint contract that all accounts will use
    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
        accountImplementation = new SmartAccount(_entryPoint);
    }

    /// @notice Creates an account, and return its address. Returns the address even if the account is already deployed
    /// @param owner The owner of the account
    /// @param salt The salt used to determine the account's address
    /// @return ret The account contract
    function createAccount(address owner, uint256 salt) external returns (SmartAccount ret) {
        address addr = getAddress(owner, salt);
        if (addr.code.length > 0) {
            return SmartAccount(payable(addr));
        }
        ret = SmartAccount(
            payable(
                new ERC1967Proxy{ salt: bytes32(salt) }(
                    address(accountImplementation), abi.encodeCall(SmartAccount.initialize, (owner))
                )
            )
        );
    }

    /// @notice Calculate the counterfactual address of an account as it would be returned by createAccount()
    /// @param owner The owner of the account
    /// @param salt The salt used to determine the account's address
    /// @return The address of the account that would be created
    function getAddress(address owner, uint256 salt) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(address(accountImplementation), abi.encodeCall(SmartAccount.initialize, (owner)))
                )
            )
        );
    }
}
