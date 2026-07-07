// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Target {
    uint256 public value;

    event Hit(address sender, uint256 value);

    function setValue(uint256 value_) external payable {
        value = value_;
        emit Hit(msg.sender, value_);
    }
}
