pragma solidity >=0.4.22 <0.7.0;

// This script is a simple variant of
// https://programtheblockchain.com/posts/2018/03/16/flipping-a-coin-in-ethereum/

contract EtherRockPaperScissors {
    enum Choice {ROCK, PAPER, SCISSORS}
    
    address public player1;
    bytes32 public player1Commitment;

    uint256 public betAmount;

    address public player2;
    Choice public player2Choice;

    uint256 public expiration;
    
    function computeCommitment(Choice choice, uint256 nonce) pure public returns(bytes32) {
        return keccak256(abi.encodePacked(choice, nonce));
    }
    
    function createBet(bytes32 commitment) public payable {
        require(player1 == 0);
        require(player2 == 0);
        require(msg.value > 0);
        
        player1 = msg.sender;
        player1Commitment = commitment;
        betAmount = msg.value;
    }

    function cancel() public {
        require(player1 != 0);
        require(player2 == 0);
        require(msg.sender == player1);

        msg.sender.transfer(address(this).balance);
        
        player1 = 0;
        betAmount = 0;
    }

    function takeBet(Choice choice) public payable {
        require(player1 != 0);
        require(player2 == 0);
        require(msg.value == betAmount);

        player2 = msg.sender;
        player2Choice = choice;

        expiration = now + 24 hours;
    }

    function reveal(Choice choice, uint256 nonce) public {
        require(player1 != 0);
        require(player2 != 0);
        require(msg.sender == player1);
        require(now < expiration);

        require(keccak256(abi.encodePacked(choice, nonce)) == player1Commitment);

        if (choice == player2Choice) {
            player1.transfer(address(this).balance / 2);
            player2.transfer(address(this).balance / 2);
        } else if (choice == Choice.ROCK) {
            if (player2Choice == Choice.PAPER) {
                player2.transfer(address(this).balance);
            } else {
                player1.transfer(address(this).balance);
            }
        } else if (choice == Choice.PAPER) {
            if (player2Choice == Choice.SCISSORS) {
                player2.transfer(address(this).balance);
            } else {
                player1.transfer(address(this).balance);
            }
        } else if (choice == Choice.SCISSORS) {
            if (player2Choice == Choice.ROCK) {
                player2.transfer(address(this).balance);
            } else {
                player1.transfer(address(this).balance);
            }
        }
        
        player1 = 0;
        player2 = 0;
        betAmount = 0;
    }

    function claimTimeout() public {
        require(player1 != 0);
        require(player2 != 0);
        require(msg.sender == player2);
        require(now >= expiration);

        player2.transfer(address(this).balance);
        
        player1 = 0;
        player2 = 0;
        betAmount = 0;
    }
}
