// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CurveBabyJubJub.sol"; //Libreria para ecc
import "./IVerifier.sol"; //Interfaz de verificadores

contract VotingSystem {

    address public owner;
    bool public electionOpen;

    uint256 public accC1x;
    uint256 public  accC1y;
    uint256 public accC2x;
    uint256 public  accC2y;

    uint256 public numberOfVotes;

    mapping(bytes32 => bool) public nullifierUsed;

    IVerifier public voteVerifier;
    IVerifier public recountVerifier;


    // --------------------
    // Events
    // --------------------

    event VoteRegistered(
        uint256[2] C1,
        uint256[2] C2,
        bytes32 nullifierHash
    );

    event ElectionClosed();

    event ResultsPublished(
        uint256 result
    );

    // --------------------
    // Constructor
    // --------------------

    constructor(
        address _voteVerifier, // Adress de los verificadores desplegados
        address _recountVerifier
    ) {
        owner = msg.sender;
        electionOpen = true;

        voteVerifier = IVerifier(_voteVerifier);
        recountVerifier = IVerifier(_recountVerifier);


        accC1x=0;
        accC1y=1;
        accC2x = 0;
        accC2y = 1;
    }

    // --------------------
    // Vote
    // --------------------

    function registerVote(
        Proof calldata proof,
        uint256[2] calldata C1,
        uint256[2] calldata C2,
        uint32[8] calldata nullifier
    ) external {
        uint256[12] memory publicInputs;
        publicInputs[0] = C1[0];
        publicInputs[1] = C1[1];
        publicInputs[2] = C2[0];
        publicInputs[3] = C2[1];
        publicInputs[4] = nullifier[0];
        publicInputs[5] = nullifier[1];
        publicInputs[6] = nullifier[2];
        publicInputs[7] = nullifier[3];
        publicInputs[8] = nullifier[4];
        publicInputs[9] = nullifier[5];
        publicInputs[10] = nullifier[6];
        publicInputs[11] = nullifier[7];




        require(electionOpen, "Votacion finalizada");
        bytes32 nullifierHash = keccak256(abi.encodePacked(nullifier)); //Lo ideal seria guardar el nullifier tal cual pero era complicado
        require(!nullifierUsed[nullifierHash], "Nullifier ya utilizado");

        // ZKP de voto válido
        bool ok = voteVerifier.verifyTx(proof, publicInputs);
        require(ok, "Invalid vote proof");

        // Marcar nullifier
        nullifierUsed[nullifierHash] = true;

        // Acumular cifrados (homomorfico)

        (accC1x, accC1y) = CurveBabyJubJub.pointAdd(accC1x, accC1y, C1[0], C1[1]);
        (accC2x, accC2y) = CurveBabyJubJub.pointAdd(accC2x, accC2y, C2[0], C2[1]);

        numberOfVotes += 1;

        emit VoteRegistered(C1, C2, nullifierHash);
    }

    // --------------------
    // Close election
    // --------------------

    function closeElection() external {
        require(msg.sender == owner, "Only owner");
        require(electionOpen, "Already closed");

        electionOpen = false;
        emit ElectionClosed();
    }

    // --------------------
    // Publish results
    // --------------------

    function publishResults(
        uint32[8] calldata result,
        Proof calldata proof
        
    ) external {

        require(msg.sender == owner, "Only owner");
        require(!electionOpen, "Election still open");

        // Verificar que result corresponde a accC1, accC2
        uint256[12] memory inputs;
        inputs[0] = accC1x;
        inputs[1] = accC1y;
        inputs[2] = accC2x;
        inputs[3] = accC2y;
        inputs[4] = result[0];
        inputs[5] = result[1];
        inputs[6] = result[2];
        inputs[7] = result[3];
        inputs[8] = result[4];
        inputs[9] = result[5];
        inputs[10] = result[6];
        inputs[11] = result[7];
        bool ok = recountVerifier.verifyTx(proof, inputs);
        require(ok, "Invalid recount proof");

        emit ResultsPublished(result[7]); //Solo publicamos el ultimo ya que la cantidad de votos posible entra en un solo uint32
    }
}
