// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockSafe {
    mapping(address module => bool enabled) public enabledModules;

    function setModule(address module, bool enabled) external {
        enabledModules[module] = enabled;
    }

    function isModuleEnabled(address module) external view returns (bool) {
        return enabledModules[module];
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        uint8
    ) external returns (bool success) {
        (success,) = to.call{value: value}(data);
    }
}
