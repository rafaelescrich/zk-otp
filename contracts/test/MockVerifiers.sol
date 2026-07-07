// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockAuthVerifier {
    bool public result = true;

    function setResult(bool result_) external {
        result = result_;
    }

    function verifyProof(
        uint256[2] calldata,
        uint256[2][2] calldata,
        uint256[2] calldata,
        uint256[7] calldata
    ) external view returns (bool) {
        return result;
    }
}

contract MockRotateVerifier {
    bool public result = true;

    function setResult(bool result_) external {
        result = result_;
    }

    function verifyProof(
        uint256[2] calldata,
        uint256[2][2] calldata,
        uint256[2] calldata,
        uint256[7] calldata
    ) external view returns (bool) {
        return result;
    }
}

contract MockRegisterVerifier {
    bool public result = true;

    function setResult(bool result_) external {
        result = result_;
    }

    function verifyProof(
        uint256[2] calldata,
        uint256[2][2] calldata,
        uint256[2] calldata,
        uint256[2] calldata
    ) external view returns (bool) {
        return result;
    }
}
