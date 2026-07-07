// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISafe} from "./interfaces/ISafe.sol";
import {IAuthVerifier, IRegisterVerifier} from "./interfaces/IZkOtpVerifiers.sol";

contract ZkOtpSafeModule {
    uint256 private constant FIELD_PRIME =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    IAuthVerifier public immutable AUTH_VERIFIER;
    IRegisterVerifier public immutable REGISTER_VERIFIER;

    mapping(address safe => bytes32 commitment) public commitmentOf;
    mapping(address safe => uint256 nonce) public nonceOf;
    mapping(address safe => mapping(bytes32 nullifier => bool used)) public usedNullifier;
    mapping(address safe => bool initialized) public initialized;

    error NotEnabledOnSafe();
    error OnlySafeCanRegister();
    error AlreadyRegistered();
    error NotRegistered();
    error NullifierUsed();
    error Expired();
    error InvalidProof();
    error PublicInputMismatch();
    error NotFieldElement();
    error SafeCallFailed();

    event Registered(address indexed safe, bytes32 commitment);
    event Executed(
        address indexed safe,
        bytes32 nullifier,
        address indexed target,
        uint256 value,
        bytes data
    );

    constructor(address auth, address register_) {
        AUTH_VERIFIER = IAuthVerifier(auth);
        REGISTER_VERIFIER = IRegisterVerifier(register_);
    }

    function register(
        address safe,
        bytes32 commitment,
        Proof calldata proof,
        uint256[2] calldata publicSignals
    ) external {
        if (msg.sender != safe) revert OnlySafeCanRegister();
        if (!ISafe(safe).isModuleEnabled(address(this))) revert NotEnabledOnSafe();
        if (initialized[safe]) revert AlreadyRegistered();
        _requireFieldElement(commitment);

        if (publicSignals[0] != uint256(commitment)) revert PublicInputMismatch();
        if (publicSignals[1] != _registrationBinding(commitment, safe, block.chainid)) {
            revert PublicInputMismatch();
        }

        if (!REGISTER_VERIFIER.verifyProof(proof.a, proof.b, proof.c, publicSignals)) {
            revert InvalidProof();
        }

        commitmentOf[safe] = commitment;
        initialized[safe] = true;
        emit Registered(safe, commitment);
    }

    function executeWithProof(
        address safe,
        address target,
        uint256 value,
        bytes calldata data,
        uint256 deadline,
        Proof calldata proof,
        uint256[7] calldata publicSignals
    ) external returns (bool) {
        if (!initialized[safe]) revert NotRegistered();
        if (!ISafe(safe).isModuleEnabled(address(this))) revert NotEnabledOnSafe();
        if (block.timestamp > deadline) revert Expired();

        bytes32 actionHash = keccak256(abi.encode(safe, target, value, data, address(this)));
        uint256 expectedNonce = nonceOf[safe];
        bytes32 nullifier = bytes32(publicSignals[6]);
        if (usedNullifier[safe][nullifier]) revert NullifierUsed();

        if (publicSignals[0] != block.chainid) revert PublicInputMismatch();
        if (publicSignals[1] != uint256(uint160(safe))) revert PublicInputMismatch();
        if (publicSignals[2] != uint256(actionHash) % FIELD_PRIME) revert PublicInputMismatch();
        if (publicSignals[3] != expectedNonce) revert PublicInputMismatch();
        if (publicSignals[4] != deadline) revert PublicInputMismatch();
        if (publicSignals[5] != uint256(commitmentOf[safe])) revert PublicInputMismatch();

        if (!AUTH_VERIFIER.verifyProof(proof.a, proof.b, proof.c, publicSignals)) {
            revert InvalidProof();
        }

        usedNullifier[safe][nullifier] = true;
        nonceOf[safe] = expectedNonce + 1;
        emit Executed(safe, nullifier, target, value, data);

        bool ok = ISafe(safe).execTransactionFromModule(target, value, data, 0);
        if (!ok) revert SafeCallFailed();
        return true;
    }

    function _registrationBinding(
        bytes32 commitment,
        address safe,
        uint256 chainId
    ) private pure returns (uint256) {
        return uint256(keccak256(abi.encode(commitment, safe, chainId))) % FIELD_PRIME;
    }

    function _requireFieldElement(bytes32 value) private pure {
        if (uint256(value) >= FIELD_PRIME) revert NotFieldElement();
    }
}
