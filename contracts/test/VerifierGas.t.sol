// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AuthVerifier} from "../src/verifiers/AuthVerifier.sol";
import {RegisterVerifier} from "../src/verifiers/RegisterVerifier.sol";
import {RotateVerifier} from "../src/verifiers/RotateVerifier.sol";

/// @notice Measures on-chain Groth16 verification gas with REAL proofs
/// (calldata from `snarkjs zkey export soliditycalldata`) and asserts the
/// exported verifiers accept valid proofs.
contract VerifierGasTest is Test {
    function test_auth_verify_gas() public {
        AuthVerifier v = new AuthVerifier();
        uint256[2] memory a = [
            0x1fefaf70f6cfad75b093d132d5457091b5e40488930ebb70316c45178f79bc74,
            0x00ef39f2aad89d1472a0955cdfde6388e2a6dbe28301488b4e111c209a8bcdb4
        ];
        uint256[2][2] memory b = [
            [0x0abd26a9c8f0e67162cf5a59173edead4619d908c4196d03249d9ca337731cc4,
             0x2ad7546fca0b58192f471b4cf1358738773f12b762f4791319fc52cae91d7fe0],
            [0x2ba4cf6c49caa7b38b44731fb6d9fe923f9e4cb9ab6471d6a75e2f4169c20a01,
             0x1a0a6471e923d8626cd305926a05e6a9a8a4a2722a3700c7ccd12df4ca10807c]
        ];
        uint256[2] memory c = [
            0x2b920f5813057af0d9060838fd8f59b712371ef26cde033f57c3c9c15398325a,
            0x080b306c1e37a241abcb5e3ad53bd1b1522b06696316d1892587754b2c9a9492
        ];
        uint256[7] memory pub = [
            0x2676ca5aebd76696393d7fd8d2c63752cad3b987f9362b40a170ebddf39802f3,
            uint256(0x89),
            uint256(0xc0),
            uint256(0x1234567890abcdef),
            uint256(0x1),
            uint256(0x02540be3ff),
            0x2536d01521137bf7b39e3fd26c1376f456ce46a45993a5d7c3c158a450fd7329
        ];
        uint256 g0 = gasleft();
        bool ok = v.verifyProof(a, b, c, pub);
        uint256 used = g0 - gasleft();
        assertTrue(ok, "real auth proof must verify");
        emit log_named_uint("auth verify gas", used);
    }

    function test_register_verify_gas() public {
        RegisterVerifier v = new RegisterVerifier();
        uint256[2] memory a = [
            0x16773e60fee8c62bd71bb8ee7541bdd90fb10eb22db39f5999567e03d6daae11,
            0x071f8d22f7a15e6d2117b2c6fc4952a822679f74f835e10de1a5cbe8fe0dadf0
        ];
        uint256[2][2] memory b = [
            [0x165548ca5af099d084acd6c6a34abaaf1f7ca3f0e8ce39d3c20f0b8ae27385ba,
             0x2929d9367a5e72a4577e5e866f78650387ac0c1ea01ccfa06aa1f9438ebc789c],
            [0x2621e2733f03256a72c7a9a5f8cfaeb407d877c026d371a7c7f10e2d8aa55641,
             0x05c11069a10e73aad415495170b988827bd121a20d10fec2a7ad68a40c82b49e]
        ];
        uint256[2] memory c = [
            0x0d5e33d2fd75bef9f1db39bd44538a0244517b04957d5bbdeab7b1ead9a8ec4c,
            0x1f3b84a409aa4feddd057435c977f71b398789a8277d846d1ec24d5582af3660
        ];
        uint256[2] memory pub = [
            0x2536d01521137bf7b39e3fd26c1376f456ce46a45993a5d7c3c158a450fd7329,
            uint256(0x0)
        ];
        uint256 g0 = gasleft();
        bool ok = v.verifyProof(a, b, c, pub);
        uint256 used = g0 - gasleft();
        assertTrue(ok, "real register proof must verify");
        emit log_named_uint("register verify gas", used);
    }

    function test_rotate_verify_gas() public {
        RotateVerifier v = new RotateVerifier();
        uint256[2] memory a = [
            0x10b19a7e7458261032a38d17e6be2f9339bfd5de13411eaf41c60d8ca8da7dba,
            0x0e9d43c8cfe9845006464525a7b3a318e4cd5465648fa2b4d089e4322b834c04
        ];
        uint256[2][2] memory b = [
            [0x26e82f7d86bcdef1db756f29334f3b9545dc3c9a4519437ab40a00df8afd9f67,
             0x1207a54164b73100fa69b9e4ac9b56814b84583633bce3390c2ccc7061527a5b],
            [0x0ddec223670aed8fe35a0403215907e1f64cbd1806b58e1914bc184240b33204,
             0x2a514848984cebe00f7b52bc4dec9c1e7d44c4f2f285efe5548d07f2e4191fae]
        ];
        uint256[2] memory c = [
            0x20fe3e68d05ad8901e702e7323ab31e98952ef878a8b18d53225a14e403ee699,
            0x1497abafb5c04cf73c1982f87ecb00812726bebd9bef8da9aab815f859073433
        ];
        uint256[7] memory pub = [
            0x0847bb927043fad3bc84448e310268d6d6db10c67fd03094e3dd79cfda6b722f,
            0x2536d01521137bf7b39e3fd26c1376f456ce46a45993a5d7c3c158a450fd7329,
            0x1cb111259febbf057f19fd0bc2734a6714ccb53dfd14c6c47a9aac0a45e7afc4,
            uint256(0x89),
            uint256(0xc0),
            uint256(0x1),
            uint256(0x02540be3ff)
        ];
        uint256 g0 = gasleft();
        bool ok = v.verifyProof(a, b, c, pub);
        uint256 used = g0 - gasleft();
        assertTrue(ok, "real rotate proof must verify");
        emit log_named_uint("rotate verify gas", used);
    }
}
