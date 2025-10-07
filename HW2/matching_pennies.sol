// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract matching_pennies {
    uint256 game_state;
    address player1;
    address player2;

    bool p1_pay;
    bool p2_pay;

    uint256 p1_context;
    uint256 p1_hash;
    uint256 p2_choice;

    constructor(){
        game_state = 0;
        p1_pay = false;
        p2_pay = false;
    }

    function new_game(address p1, address p2) public returns (uint256){
        require(game_state == 0, "Ya hay un juego en progreso");
        player1 = p1;
        player2 = p2;
        game_state = 1; //Cambia el estado del juego
        p1_context = block.timestamp;
        return p1_context;
    }

    receive() external payable {
        if (msg.sender == player1 && msg.value == 0.01 ether){
            p1_pay = true;
        } else if (msg.sender == player2 && msg.value == 0.01 ether){
            p2_pay = true;
        }
        else {
            revert("Pago invalido");
        }
     }

    function player1Play(uint256 hash) public{
        require(p1_pay, "Deposite 0.01 eth para jugar");
        require(game_state == 1 && msg.sender == player1, "No es tu turno");
        p1_hash = hash;
        game_state = 2; //Ahora le toca al jugador 2
    }

    function player2Play(bool choice) public{
        require(p2_pay, "Deposite 0.01 eth para jugar");
        require(game_state == 2 && msg.sender == player2, "No es tu turno");
        if(choice){p2_choice = 1;}
        else {p2_choice = 0;}
        game_state = 3;
    }

    function player1Reveal(uint256 nonce, uint256 value) public {
        require(game_state == 3 && msg.sender == player1, "No es tu turno");
        require(p1_pay && p2_pay);
        if(p1_hash ==  uint256(keccak256(abi.encode(nonce, value, p1_context)))){
            if (value == p2_choice){
                p1_pay = false;
                p2_pay = false;
                bool sent = payable(player1).send(address(this).balance);
                require(sent, "Failed to send Ether");
            }
            else{
                p1_pay = false;
                p2_pay = false;
                bool sent = payable(player2).send(address(this).balance);
                require(sent, "Failed to send Ether");
            }
        }
        game_state = 0;
    }

    function cleanGame() public{
        require((msg.sender == player1 || msg.sender == player2) && game_state != 0);
        if(!p2_pay){
            p1_pay = false;
            game_state = 0;
            bool sent = payable(player1).send(address(this).balance);
            require(sent, "Failed to send Ether");
        } else if (!p1_pay) {
            p2_pay = false;
            game_state = 0;
            bool sent = payable(player2).send(address(this).balance);
            require(sent, "Failed to send Ether");
        } else if(game_state == 3 && block.timestamp > p1_context + 86400){ // Si ya paso un dia sin que el primer jugador revele
            // Doy por sentado que el p1 no reveló porque su elección no lo hacía ganar, gana por default el jugador 2
            p1_pay = false;
            p2_pay = false;
            game_state = 0;
            bool sent = payable(player2).send(address(this).balance);
            require(sent, "Failed to send Ether");
        }
    }

    function pureCalculateHash(uint256 nonce, uint256 value) public view returns (bytes32) {
        return keccak256(abi.encode(nonce, value, p1_context));
    }

    function viewContext() public view returns (uint256) {
        return p1_context;
    }

    function viewState() public view returns (uint256) {
        return game_state;
    }
}