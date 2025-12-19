// SPDX-License-Identifier: GPL-3.0

// Interfaz del verificador, para enseñarle al contrato como llamar a la función verifyTx de los verificadores
// Los verifier.sol se crean utilizando ZoKrates
    // votoValido.zok -> voteVerifier.sol
    // recuentoValido.zol -> recountVerifier.sol
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

struct G1Point {
    uint X;
    uint Y;
}

struct G2Point {
    uint[2] X;
    uint[2] Y;
}

struct Proof{
    G1Point a;
    G2Point b;
    G1Point c;
}

interface IVerifier {
    function verifyTx(
        Proof calldata p,
        uint[12] calldata input
    ) external view returns (bool r);
}