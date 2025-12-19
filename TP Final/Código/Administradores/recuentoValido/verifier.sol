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

contract RecountVerifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x175d9ada8ad3d673ec4e931681b0d7a26c4f36a58ae84a1b295199c867aa3369), uint256(0x1cb6d84a21ac7bf60c9515e11da9593e5f530914e62fa771d6bc07c5db904750));
        vk.beta = Pairing.G2Point([uint256(0x089d156e144f7305936444375b4cc7181f915fe68b25d6b3bf65119d864d9b21), uint256(0x09db696913b80c1939b40951b285d5c4e338c03342a748ade6ab817a5cb0ee82)], [uint256(0x176997985d166609dc7a47b760c4f6780f511a7d27259bbe5344a9177616ca87), uint256(0x028711aa31536e37a4f722936aa002b9c58dfab25b1d73d49c86d0bfb3fbf20c)]);
        vk.gamma = Pairing.G2Point([uint256(0x21377aed878ccdfd25bf78b5900d59fea5fe1c611a52ada30e4a1db4b56dd9cf), uint256(0x07f9b3ad2a783104e0149b773d1c4839546b7c6d37d9b5a57365dea35e9d3fa2)], [uint256(0x05403723e894851758127010647ede3c93f0b7485b169f0582dc4cbc83ba4fa0), uint256(0x2a88bbec5d06d5da5a925cf95e785ad17659e7909d893efbb7498059656247d2)]);
        vk.delta = Pairing.G2Point([uint256(0x2e73d8239f8a2b308aefb4ea26bbae05ecae75b50730202a7bc726fab8f3e3f3), uint256(0x2ca03233dd5977252d4103391f481bbb2b54045a097b8844886d3aef8fb3caeb)], [uint256(0x04f88e9ca94a33413e334da175c56b48c36335600b8cf2325bd05028bae2b95b), uint256(0x0af44214f16396ef136aedf645c6a216d831ad638194cc7e9c8d28b8888e3f1c)]);
        vk.gamma_abc = new Pairing.G1Point[](13);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0e201d343dbcf5e6b5e4a075ec32f64a5ac664a2a0bd1de415a476571ba1046e), uint256(0x180facfcab2b26415945212a45208af5d469b6236e90c67374a3a217a7416d0f));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0a88ff5e18f2143c9d8addcaef4910a11d4343761834d5ea9a1d660a2c88ef33), uint256(0x16ba00fd63dfb3694ca507dfba15e7991f1c4d3652816be51574fb15068b41b2));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x20158cd6c574e6f36e4674d6e2683fb54c163f7e1a80c69e092f3616c4ac8079), uint256(0x0d2121d1ccb6225f730a2c27781fd95d72170afe991f62c79875b5100b148c7b));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x044be0b97c7dbc1f11e3fb7caa31f51483904487ddfb1d42e89f7acb439d1f28), uint256(0x00289c58ea63a9ca9f5385e2e293020c66d188203233ea947bd6bee5889e1816));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1f454a3e058d5e5f957bf311a4abe9c06178b9cd4377e5069637fa8a9d54806e), uint256(0x2ac87dbe6133d43f5cff1341dae875e21a6a8c7ffc2c805a462cd099b3825b22));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x20de689e8d8627681dc897f64b5ac8392f305e71e793ad898d475c2f3f7bc78a), uint256(0x2fc19219849608169e6a75bb4c0677ce95ecbb68c9dc0406661500ca3771b4ce));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x04638a6a973c9d34e8efc4e81d8daee9e2a4348e67ea78bcceed059369a1c1b2), uint256(0x29e52f7cb1a95a23e9f798e53e1ec728803ddd757ffc145415d920e5945402ae));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1b6da140d44329cec48dfa1f0dafd0743ddbad84d8df76257a3d8784f0cd292b), uint256(0x0c309831836559ddf8a195c59e11c033cbb5de4b339bc71be2bfb9e138c445f9));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2bcba9658599d9be5dccea1e0e8e7b8a44f6f6e939ec1c6c38fa049b60ed768e), uint256(0x0367b62146df490c14291b88ae4fb5bc0a6fa59f3b615d3af81bdcd68fb9b38f));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x2095bada49bc2e8619bc639b9c159a4b9d1a4c25a7f5ddee84e6fe7908d6f893), uint256(0x023684cb15dd49822ad3d6ab7860aadb62ca99d0e659cf197d174394e764ec1a));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1adda30f54ea76a40c964f05692173eeea2480f28cc711873e96417079480916), uint256(0x2fe2812b83fd65b8d83cb71c508e2225a8d78ca1ea24c1847b724faeeed9500e));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x068f51a8671175512c2499778caf4d95eb3ef06db4534241a42fa310f21e47a7), uint256(0x088118dcf33ebb9f46a7b28c2f37c1791f8b7e1a08c6f38455b7509ddf1c99df));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x036e8073e435a2d258cfc0bb671009764a50cec09a6b387d0440ae2954cea361), uint256(0x05cce6afed56c5af7f7be7de6da8c25be330ebbdf5459f34cf689a011cc7548b));
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
