// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external returns (bool success);

    function isModuleEnabled(address module) external view returns (bool);
}
