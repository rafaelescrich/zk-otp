// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ZkOtpSafeModule} from "../src/ZkOtpSafeModule.sol";
import {MockAuthVerifier, MockRegisterVerifier} from "./MockVerifiers.sol";
import {MockSafe} from "./MockSafe.sol";
import {Target} from "./Target.sol";

contract ZkOtpSafeModuleTest is Test {
    uint256 private constant FIELD_PRIME =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    MockAuthVerifier authVerifier;
    MockRegisterVerifier registerVerifier;
    ZkOtpSafeModule module;
    MockSafe safe;

    function setUp() public {
        authVerifier = new MockAuthVerifier();
        registerVerifier = new MockRegisterVerifier();
        module = new ZkOtpSafeModule(address(authVerifier), address(registerVerifier));
        safe = new MockSafe();
        safe.setModule(address(module), true);
    }

    function testSafeRegistersThroughSafeAddressOnly() public {
        bytes32 commitment = bytes32(uint256(123));
        ZkOtpSafeModule.Proof memory proof;

        vm.expectRevert(ZkOtpSafeModule.OnlySafeCanRegister.selector);
        module.register(address(safe), commitment, proof, _registerSignals(commitment));

        vm.prank(address(safe));
        module.register(address(safe), commitment, proof, _registerSignals(commitment));

        assertEq(module.commitmentOf(address(safe)), commitment);
    }

    function testSafeRegisterRejectsNonFieldCommitment() public {
        bytes32 commitment = bytes32(FIELD_PRIME);
        ZkOtpSafeModule.Proof memory proof;

        vm.expectRevert(ZkOtpSafeModule.NotFieldElement.selector);
        vm.prank(address(safe));
        module.register(address(safe), commitment, proof, _registerSignals(commitment));
    }

    function testExecuteWithProofCallsSafeModulePath() public {
        bytes32 commitment = bytes32(uint256(123));
        ZkOtpSafeModule.Proof memory proof;
        vm.prank(address(safe));
        module.register(address(safe), commitment, proof, _registerSignals(commitment));

        Target target = new Target();
        bytes memory data = abi.encodeCall(Target.setValue, (7702));
        uint256 deadline = block.timestamp + 300;
        uint256[7] memory signals =
            _authSignals(address(target), 0, data, deadline, commitment, 0, 555);

        assertTrue(
            module.executeWithProof(address(safe), address(target), 0, data, deadline, proof, signals)
        );

        assertEq(target.value(), 7702);
        assertEq(module.nonceOf(address(safe)), 1);
        assertTrue(module.usedNullifier(address(safe), bytes32(uint256(555))));
    }

    function _registerSignals(bytes32 commitment) private view returns (uint256[2] memory signals) {
        signals[0] = uint256(commitment);
        signals[1] = uint256(keccak256(abi.encode(commitment, address(safe), block.chainid)))
            % FIELD_PRIME;
    }

    function _authSignals(
        address target,
        uint256 value,
        bytes memory data,
        uint256 deadline,
        bytes32 commitment,
        uint256 nonce,
        uint256 nullifier
    ) private view returns (uint256[7] memory signals) {
        bytes32 actionHash = keccak256(abi.encode(address(safe), target, value, data, address(module)));
        signals[0] = block.chainid;
        signals[1] = uint256(uint160(address(safe)));
        signals[2] = uint256(actionHash) % FIELD_PRIME;
        signals[3] = nonce;
        signals[4] = deadline;
        signals[5] = uint256(commitment);
        signals[6] = nullifier;
    }
}
