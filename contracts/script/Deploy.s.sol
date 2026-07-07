// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {ZkOtpDelegate} from "../src/ZkOtpDelegate.sol";
import {ZkOtpSafeModule} from "../src/ZkOtpSafeModule.sol";

contract Deploy is Script {
    function run() external returns (ZkOtpDelegate delegate, ZkOtpSafeModule module) {
        address authVerifier = vm.envAddress("AUTH_VERIFIER");
        address rotateVerifier = vm.envAddress("ROTATE_VERIFIER");
        address registerVerifier = vm.envAddress("REGISTER_VERIFIER");

        vm.startBroadcast();
        delegate = new ZkOtpDelegate(authVerifier, rotateVerifier, registerVerifier);
        module = new ZkOtpSafeModule(authVerifier, registerVerifier);
        vm.stopBroadcast();
    }
}
