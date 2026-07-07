pragma circom 2.1.6;

include "circomlib/circuits/poseidon.circom";

template ZkOtpAuth() {
    signal input chainId;
    signal input verifyingContract;
    signal input actionHash;
    signal input nonce;
    signal input deadline;
    signal input commitment;

    signal input secret;
    signal input salt;

    signal output nullifier;

    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== secret;
    commitmentHasher.inputs[1] <== salt;
    commitment === commitmentHasher.out;

    component challengeHasher = Poseidon(6);
    challengeHasher.inputs[0] <== chainId;
    challengeHasher.inputs[1] <== verifyingContract;
    challengeHasher.inputs[2] <== actionHash;
    challengeHasher.inputs[3] <== nonce;
    challengeHasher.inputs[4] <== deadline;
    challengeHasher.inputs[5] <== commitment;

    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== secret;
    nullifierHasher.inputs[1] <== challengeHasher.out;
    nullifier <== nullifierHasher.out;
}

component main { public [
    chainId,
    verifyingContract,
    actionHash,
    nonce,
    deadline,
    commitment
] } = ZkOtpAuth();
