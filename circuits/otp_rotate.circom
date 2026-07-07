pragma circom 2.1.6;

include "circomlib/circuits/poseidon.circom";

template ZkOtpRotate() {
    signal input oldCommitment;
    signal input newCommitment;
    signal input chainId;
    signal input verifyingContract;
    signal input nonce;
    signal input deadline;

    signal input oldSecret;
    signal input oldSalt;
    signal input newSecret;
    signal input newSalt;

    signal output nullifier;

    component oldCommitmentHasher = Poseidon(2);
    oldCommitmentHasher.inputs[0] <== oldSecret;
    oldCommitmentHasher.inputs[1] <== oldSalt;
    oldCommitment === oldCommitmentHasher.out;

    component newCommitmentHasher = Poseidon(2);
    newCommitmentHasher.inputs[0] <== newSecret;
    newCommitmentHasher.inputs[1] <== newSalt;
    newCommitment === newCommitmentHasher.out;

    component challengeHasher = Poseidon(6);
    challengeHasher.inputs[0] <== chainId;
    challengeHasher.inputs[1] <== verifyingContract;
    challengeHasher.inputs[2] <== oldCommitment;
    challengeHasher.inputs[3] <== newCommitment;
    challengeHasher.inputs[4] <== nonce;
    challengeHasher.inputs[5] <== deadline;

    component nullifierHasher = Poseidon(2);
    nullifierHasher.inputs[0] <== oldSecret;
    nullifierHasher.inputs[1] <== challengeHasher.out;
    nullifier <== nullifierHasher.out;
}

component main { public [
    oldCommitment,
    newCommitment,
    chainId,
    verifyingContract,
    nonce,
    deadline
] } = ZkOtpRotate();
