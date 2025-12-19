// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x0daa57dc4a4692c2ac1f2b06c0f5be3297fb59681cb6ee071334ab6435f6f39f), uint256(0x072515937d4f66f7fd7bd111c87c377f41a6724c4445437f3238c46fd413afc6));
        vk.beta = Pairing.G2Point([uint256(0x2de1f7c564d6a0ca0431221e98101d1d71b0e68f915032b7381e9e6301ad3de6), uint256(0x118c304086f3359014d0af4f4c87571decff530aaa45da37c133aca4ec537d71)], [uint256(0x117846116db6bdbc400b5b1ed1a5c227aa3b556573b80c1403bc34d7a3f0e751), uint256(0x167a659204992d15584e0c75e4a7e47a30c03023fe19dac1aab163e817f8dc75)]);
        vk.gamma = Pairing.G2Point([uint256(0x2968ed1423c743f4f1410c66985a635ff325e21a895c94589331b70554cd4fa8), uint256(0x016b68374b6d4825747c83cee8c589e8deb7be7f63c83c80c85985387aa3c9cd)], [uint256(0x0cb42d30f5ceedaa6936c083e68e6adc0b386d36a86059a305624b998cdb0a28), uint256(0x0774bee6b76b7fc994e2349dcdd8f1fca28a67e9b07509dc4f249bda432087e4)]);
        vk.delta = Pairing.G2Point([uint256(0x0e9a7e0c5e9237e049821a9b96107098c0f878977a78ca983233ac9174ce87eb), uint256(0x2bb21a00ec8b20398799687107808f1d8c7bfe515cfc6db2a0a5e468896b08d1)], [uint256(0x22647b8cf8e82011242b5d9638f6efc0b72e0bfdc1a1b2cfaa4e578712c34787), uint256(0x02566cb9c3ddfa185320ded12e3f3f1e27a161d1fbe4a7f3cad3e35cf71b33fb)]);
        vk.gamma_abc = new Pairing.G1Point[](13);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x2af849b578726a614b9cf837813b1920d037d44d4fb4bc16f12191fad80f49a7), uint256(0x2996abb657ecb50682bdddffaebaa1d8ac4f24f9e9a0316061f3b752eeb45eb2));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0f712efb483b65815be9b69fcba66737d47b7cbe013e8de2d2165c24b049d9cc), uint256(0x0ca7b9adfe5ab02ce2a736b251a7445727bbb4976609c2f64afb79e10c887aa8));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x257841b48225a6a393bef459cfbadd860b062e3a4cfcdcd84e1f17a8566b5a2f), uint256(0x1a2651a33495d6fc0cad673183fdf57e17633cad5bb5f498bcec10cfab67cfde));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x094e3cd70d9e5d64a4d8edabce7da6c82886b83e2f354b11c52fab27889b34a3), uint256(0x2dacdd83d24d55f4a68f7d2b3b93f9cd3211c1d20ab137daa2f400c52339a8fe));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0d4a741a96da6c76bfaec796252395489e90cfe4433878dca9302fbb46df0226), uint256(0x061594c538bc606f36887a7e1c66ac8a961afaddcc804ad7ffc4b90f0a4c3e06));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x193a0d2b254ffea955d5785440b9207c678aacb1a3f53d9e3e9ca3b686462922), uint256(0x24d34ba9aeb28b477546bfcd799b397b126c2e900cf52fd8d75b613b0f3d0fbd));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1444833fd0171d0153fe099b605a3acc2d59e21ab4cf6363f48e3f356a69febd), uint256(0x007b3259fca2e2081506324d1e635984ffa6e96617c3af356b144a9f4f0d2b4f));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0754b8b3c860c7a0bade23151b313fb3603fb8ed9ab46870bba02ce6a8947fc6), uint256(0x27aa34fcf45b39af9a1cc47f5f445d38bffb9daaaef0abff7ca0cf5690d3a5bb));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0c3a9b3069b87a21366c0747c8dc11116a494115bef45835ad706c3e9263a626), uint256(0x0679d15a217ecd95db26f4c3b63441f3aee0dbd429e658b1d6b8ba11204ad900));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x1bbc2288469bcee3f68e84dee9b37b42d6170e0fe13bae9e9ad7533ef51d0e6b), uint256(0x0b699e3e8f4c9081e4ca6ec357938656e4672743692d8ca6c46c2276ec3beacd));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x104f36c1bd12a5ef51ddef228954b3e83aad23ccb1f62ae85a5bcda689574f73), uint256(0x1da183ca55536270a093a0cae171e4460b529d9a4d934aa2b5c560d1012a2403));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x2ff01214ab73082c36227a00198362112a9b699f3bdb527f2b63ac16894fa44d), uint256(0x2e2ae1c36df72ce92b54f3c43b8271c3c8bf9c6e77f6c52b96c56cf4d0b8bb86));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x2a7dac41610238196b131c0ab8b9bae8e29516450c1d059a3e55047bc709a7dd), uint256(0x30601d27494f77eb029cc892a1b9bc46adc00de4d115c379d5fb5224dcc05b47));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[12] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](12);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
