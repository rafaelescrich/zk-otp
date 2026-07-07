pragma circom 2.1.6;

include "circomlib/circuits/poseidon.circom";

template ZkOtpRegister() {
    signal input commitment;
    signal input bindingHash;

    signal input secret;
    signal input salt;

    component commitmentHasher = Poseidon(2);
    commitmentHasher.inputs[0] <== secret;
    commitmentHasher.inputs[1] <== salt;
    commitment === commitmentHasher.out;

    // The contract checks bindingHash against keccak256(commitment, account, chainId)
    // reduced into Fr. Keep it public so calldata cannot omit the runtime domain tag.
    bindingHash === bindingHash;
}

component main { public [commitment, bindingHash] } = ZkOtpRegister();
