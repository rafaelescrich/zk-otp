// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ZkOtpDelegate} from "../src/ZkOtpDelegate.sol";
import {MockAuthVerifier, MockRegisterVerifier, MockRotateVerifier} from "./MockVerifiers.sol";
import {Target} from "./Target.sol";

contract ZkOtpDelegateTest is Test {
    uint256 private constant FIELD_PRIME =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    MockAuthVerifier authVerifier;
    MockRotateVerifier rotateVerifier;
    MockRegisterVerifier registerVerifier;
    ZkOtpDelegate delegate;

    function setUp() public {
        authVerifier = new MockAuthVerifier();
        rotateVerifier = new MockRotateVerifier();
        registerVerifier = new MockRegisterVerifier();
        delegate = new ZkOtpDelegate(
            address(authVerifier), address(rotateVerifier), address(registerVerifier)
        );
    }

    function testRegisterRequiresSelfCall() public {
        ZkOtpDelegate.Proof memory proof;
        uint256[2] memory signals;

        vm.expectRevert(ZkOtpDelegate.OnlySelf.selector);
        delegate.register(bytes32(uint256(123)), proof, signals);
    }

    function testRegisterStoresCommitment() public {
        bytes32 commitment = bytes32(uint256(123));
        ZkOtpDelegate.Proof memory proof;
        uint256[2] memory signals = _registerSignals(commitment);

        vm.prank(address(delegate));
        delegate.register(commitment, proof, signals);

        assertEq(delegate.commitment(), commitment);
        assertTrue(delegate.isInitialized());
    }

    function testRegisterRejectsNonFieldCommitment() public {
        bytes32 commitment = bytes32(FIELD_PRIME);
        ZkOtpDelegate.Proof memory proof;

        vm.expectRevert(ZkOtpDelegate.NotFieldElement.selector);
        vm.prank(address(delegate));
        delegate.register(commitment, proof, _registerSignals(commitment));
    }

    function testExecuteWithProofChecksPublicSignalsAndMarksNullifier() public {
        bytes32 commitment = bytes32(uint256(123));
        ZkOtpDelegate.Proof memory proof;
        vm.prank(address(delegate));
        delegate.register(commitment, proof, _registerSignals(commitment));

        Target target = new Target();
        ZkOtpDelegate.Call[] memory calls = new ZkOtpDelegate.Call[](1);
        calls[0] = ZkOtpDelegate.Call({
            target: address(target),
            value: 0,
            data: abi.encodeCall(Target.setValue, (451))
        });

        uint256 deadline = block.timestamp + 300;
        uint256[7] memory signals = _authSignals(calls, deadline, commitment, 0, 999);

        vm.prank(address(delegate));
        delegate.executeWithProof(calls, deadline, proof, signals);

        assertEq(target.value(), 451);
        assertEq(delegate.nonce(), 1);
        assertTrue(delegate.isNullifierUsed(bytes32(uint256(999))));
    }

    function testExecuteRejectsReplay() public {
        bytes32 commitment = bytes32(uint256(123));
        ZkOtpDelegate.Proof memory proof;
        vm.prank(address(delegate));
        delegate.register(commitment, proof, _registerSignals(commitment));

        ZkOtpDelegate.Call[] memory calls = new ZkOtpDelegate.Call[](0);
        uint256 deadline = block.timestamp + 300;
        uint256[7] memory signals = _authSignals(calls, deadline, commitment, 0, 999);

        vm.prank(address(delegate));
        delegate.executeWithProof(calls, deadline, proof, signals);

        vm.expectRevert(ZkOtpDelegate.NullifierUsed.selector);
        vm.prank(address(delegate));
        delegate.executeWithProof(calls, deadline, proof, signals);
    }

    function testRotateUpdatesCommitmentAndNonce() public {
        bytes32 commitment = bytes32(uint256(123));
        bytes32 nextCommitment = bytes32(uint256(456));
        ZkOtpDelegate.Proof memory proof;
        vm.prank(address(delegate));
        delegate.register(commitment, proof, _registerSignals(commitment));

        uint256 deadline = block.timestamp + 300;
        uint256[7] memory signals;
        signals[0] = uint256(commitment);
        signals[1] = uint256(nextCommitment);
        signals[2] = block.chainid;
        signals[3] = uint256(uint160(address(delegate)));
        signals[4] = 0;
        signals[5] = deadline;
        signals[6] = 222;

        vm.prank(address(delegate));
        delegate.rotate(nextCommitment, deadline, proof, signals);

        assertEq(delegate.commitment(), nextCommitment);
        assertEq(delegate.nonce(), 1);
        assertTrue(delegate.isNullifierUsed(bytes32(uint256(222))));
    }

    function testRotateRejectsNonFieldCommitment() public {
        bytes32 commitment = bytes32(uint256(123));
        bytes32 nextCommitment = bytes32(FIELD_PRIME);
        ZkOtpDelegate.Proof memory proof;
        vm.prank(address(delegate));
        delegate.register(commitment, proof, _registerSignals(commitment));

        uint256[7] memory signals;

        vm.expectRevert(ZkOtpDelegate.NotFieldElement.selector);
        vm.prank(address(delegate));
        delegate.rotate(nextCommitment, block.timestamp + 300, proof, signals);
    }

    function _registerSignals(bytes32 commitment) private view returns (uint256[2] memory signals) {
        signals[0] = uint256(commitment);
        signals[1] = uint256(keccak256(abi.encode(commitment, address(delegate), block.chainid)))
            % FIELD_PRIME;
    }

    function _authSignals(
        ZkOtpDelegate.Call[] memory calls,
        uint256 deadline,
        bytes32 commitment,
        uint256 nonce,
        uint256 nullifier
    ) private view returns (uint256[7] memory signals) {
        signals[0] = block.chainid;
        signals[1] = uint256(uint160(address(delegate)));
        signals[2] = uint256(keccak256(abi.encode(calls))) % FIELD_PRIME;
        signals[3] = nonce;
        signals[4] = deadline;
        signals[5] = uint256(commitment);
        signals[6] = nullifier;
    }
}
