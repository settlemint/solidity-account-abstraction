// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "account-abstraction/core/EntryPoint.sol";

contract CustomEntryPoint is EntryPoint {
    constructor(uint256 _paymasterStake, uint32 _unstakeDelaySec) EntryPoint(_paymasterStake, _unstakeDelaySec) { }
}
