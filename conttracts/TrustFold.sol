// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TrustFold
 * @dev A simple smart contract for creating and releasing escrow-based trust transactions between two parties.
 */

contract TrustFold {
    struct Escrow {
        address payable sender;
        address payable receiver;
        uint amount;
        bool isReleased;
    }

    mapping(uint => Escrow) public escrows;
    uint public escrowCount;

    event EscrowCreated(uint escrowId, address indexed sender, address indexed receiver, uint amount);
    event EscrowReleased(uint escrowId, address indexed receiver, uint amount);
    event EscrowRefunded(uint escrowId, address indexed sender, uint amount);

    /**
     * @dev Create a new escrow between sender and receiver.
     * The sender deposits ETH that will be held until released.
     */
    function createEscrow(address payable _receiver) external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        escrowCount++;

        escrows[escrowCount] = Escrow(payable(msg.sender), _receiver, msg.value, false);
        emit EscrowCreated(escrowCount, msg.sender, _receiver, msg.value);
    }

    /**
     * @dev Release funds to receiver if escrow exists and not already released.
     */
    function releaseEscrow(uint _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.sender, "Only sender can release funds");
        require(!escrow.isReleased, "Funds already released");

        escrow.isReleased = true;
        escrow.receiver.transfer(escrow.amount);
        emit EscrowReleased(_escrowId, escrow.receiver, escrow.amount);
    }

    /**
     * @dev Refund the escrow back to sender if not released yet.
     */
    function refundEscrow(uint _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.receiver || msg.sender == escrow.sender, "Unauthorized access");
        require(!escrow.isReleased, "Funds already released");

        uint amount = escrow.amount;
        escrow.amount = 0;
        escrow.sender.transfer(amount);
        emit EscrowRefunded(_escrowId, escrow.sender, amount);
    }
}
