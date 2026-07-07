// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAuthVerifier, IRegisterVerifier, IRotateVerifier} from "./interfaces/IZkOtpVerifiers.sol";

contract ZkOtpDelegate {
    bytes32 private constant STORAGE_LOCATION =
        0x9ad7e3e5ad8b6e5b3f8d0e1a4b3c2a8f3e9d4c5a6b7c8d9e0f1a2b3c4d5e6f00;

    uint256 private constant FIELD_PRIME =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct ZkOtpStorage {
        bytes32 commitment;
        uint256 nonce;
        mapping(bytes32 nullifier => bool used) usedNullifier;
        bool initialized;
    }

    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    IAuthVerifier public immutable AUTH_VERIFIER;
    IRotateVerifier public immutable ROTATE_VERIFIER;
    IRegisterVerifier public immutable REGISTER_VERIFIER;

    error OnlySelf();
    error NotInitialized();
    error AlreadyInitialized();
    error NullifierUsed();
    error Expired();
    error InvalidProof();
    error PublicInputMismatch();
    error NotFieldElement();
    error CallFailed(uint256 index, bytes returndata);

    event Registered(bytes32 commitment);
    event Rotated(bytes32 oldCommitment, bytes32 newCommitment);
    event Authenticated(bytes32 nullifier, bytes32 actionHash, uint256 nonce);

    constructor(address auth, address rotate_, address register_) {
        AUTH_VERIFIER = IAuthVerifier(auth);
        ROTATE_VERIFIER = IRotateVerifier(rotate_);
        REGISTER_VERIFIER = IRegisterVerifier(register_);
    }

    modifier onlySelf() {
        _onlySelf();
        _;
    }

    function _onlySelf() internal view {
        if (msg.sender != address(this)) revert OnlySelf();
    }

    function register(
        bytes32 commitment_,
        Proof calldata proof,
        uint256[2] calldata publicSignals
    ) external onlySelf {
        ZkOtpStorage storage $ = _store();
        if ($.initialized) revert AlreadyInitialized();
        _requireFieldElement(commitment_);

        if (publicSignals[0] != uint256(commitment_)) revert PublicInputMismatch();
        if (publicSignals[1] != _registrationBinding(commitment_, address(this), block.chainid)) {
            revert PublicInputMismatch();
        }

        if (!REGISTER_VERIFIER.verifyProof(proof.a, proof.b, proof.c, publicSignals)) {
            revert InvalidProof();
        }

        $.commitment = commitment_;
        $.initialized = true;
        emit Registered(commitment_);
    }

    function executeWithProof(
        Call[] calldata calls,
        uint256 deadline,
        Proof calldata proof,
        uint256[7] calldata publicSignals
    ) external payable onlySelf {
        ZkOtpStorage storage $ = _store();
        if (!$.initialized) revert NotInitialized();
        if (block.timestamp > deadline) revert Expired();

        bytes32 actionHash = keccak256(abi.encode(calls));
        uint256 expectedNonce = $.nonce;
        bytes32 nullifier = bytes32(publicSignals[6]);
        if ($.usedNullifier[nullifier]) revert NullifierUsed();

        _checkAuthSignals(
            publicSignals,
            block.chainid,
            address(this),
            actionHash,
            expectedNonce,
            deadline,
            $.commitment
        );

        if (!AUTH_VERIFIER.verifyProof(proof.a, proof.b, proof.c, publicSignals)) {
            revert InvalidProof();
        }

        $.usedNullifier[nullifier] = true;
        $.nonce = expectedNonce + 1;
        emit Authenticated(nullifier, actionHash, expectedNonce);

        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory returndata) =
                calls[i].target.call{value: calls[i].value}(calls[i].data);
            if (!ok) revert CallFailed(i, returndata);
        }
    }

    function rotate(
        bytes32 newCommitment,
        uint256 deadline,
        Proof calldata proof,
        uint256[7] calldata publicSignals
    ) external onlySelf {
        ZkOtpStorage storage $ = _store();
        if (!$.initialized) revert NotInitialized();
        if (block.timestamp > deadline) revert Expired();
        _requireFieldElement(newCommitment);

        bytes32 oldCommitment = $.commitment;
        bytes32 nullifier = bytes32(publicSignals[6]);
        if ($.usedNullifier[nullifier]) revert NullifierUsed();

        if (publicSignals[0] != uint256(oldCommitment)) revert PublicInputMismatch();
        if (publicSignals[1] != uint256(newCommitment)) revert PublicInputMismatch();
        if (publicSignals[2] != block.chainid) revert PublicInputMismatch();
        if (publicSignals[3] != uint256(uint160(address(this)))) revert PublicInputMismatch();
        if (publicSignals[4] != $.nonce) revert PublicInputMismatch();
        if (publicSignals[5] != deadline) revert PublicInputMismatch();

        if (!ROTATE_VERIFIER.verifyProof(proof.a, proof.b, proof.c, publicSignals)) {
            revert InvalidProof();
        }

        $.usedNullifier[nullifier] = true;
        $.nonce += 1;
        $.commitment = newCommitment;
        emit Rotated(oldCommitment, newCommitment);
    }

    function commitment() external view returns (bytes32) {
        return _store().commitment;
    }

    function nonce() external view returns (uint256) {
        return _store().nonce;
    }

    function isInitialized() external view returns (bool) {
        return _store().initialized;
    }

    function isNullifierUsed(bytes32 nullifier) external view returns (bool) {
        return _store().usedNullifier[nullifier];
    }

    receive() external payable {}

    fallback() external payable {
        revert("ZkOtpDelegate: unknown selector");
    }

    function _store() private pure returns (ZkOtpStorage storage $) {
        bytes32 slot = STORAGE_LOCATION;
        assembly {
            $.slot := slot
        }
    }

    function _checkAuthSignals(
        uint256[7] calldata publicSignals,
        uint256 chainId,
        address verifyingContract,
        bytes32 actionHash,
        uint256 expectedNonce,
        uint256 deadline,
        bytes32 commitment_
    ) private pure {
        if (publicSignals[0] != chainId) revert PublicInputMismatch();
        if (publicSignals[1] != uint256(uint160(verifyingContract))) revert PublicInputMismatch();
        if (publicSignals[2] != uint256(actionHash) % FIELD_PRIME) revert PublicInputMismatch();
        if (publicSignals[3] != expectedNonce) revert PublicInputMismatch();
        if (publicSignals[4] != deadline) revert PublicInputMismatch();
        if (publicSignals[5] != uint256(commitment_)) revert PublicInputMismatch();
    }

    function _registrationBinding(
        bytes32 commitment_,
        address account,
        uint256 chainId
    ) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(commitment_, account, chainId))) % FIELD_PRIME;
    }

    function _requireFieldElement(bytes32 value) private pure {
        if (uint256(value) >= FIELD_PRIME) revert NotFieldElement();
    }
}
