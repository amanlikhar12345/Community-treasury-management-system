// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Community Treasury Management System
 * @dev Allows members to propose, vote, and manage funds transparently.
 */
contract Project {
    struct Proposal {
        string description;
        uint256 amount;
        address payable recipient;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voters;
    }

    address public owner;
    mapping(address => bool) public members;
    uint256 public memberCount;

    mapping(uint256 => Proposal) private proposals;
    uint256 public proposalCount;

    event MemberAdded(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 amount, address recipient);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only member");
        _;
    }

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
        memberCount = 1;
    }

    function addMember(address _member) external onlyOwner {
        require(!members[_member], "Already a member");
        members[_member] = true;
        memberCount++;
        emit MemberAdded(_member);
    }

    function createProposal(string memory _description, uint256 _amount, address payable _recipient) external onlyMember {
        require(_amount <= address(this).balance, "Insufficient treasury funds");

        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.description = _description;
        p.amount = _amount;
        p.recipient = _recipient;
        p.executed = false;

        emit ProposalCreated(proposalCount, _description, _amount, _recipient);
    }

    function vote(uint256 _proposalId, bool support) external onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Proposal executed");
        require(!p.voters[msg.sender], "Already voted");

        p.voters[msg.sender] = true;
        if (support) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }

        emit Voted(_proposalId, msg.sender, support);
    }

    function executeProposal(uint256 _proposalId) external onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(!p.executed, "Already executed");
        require(p.votesFor > p.votesAgainst, "Proposal not approved");
        require(p.amount <= address(this).balance, "Insufficient funds");

        p.executed = true;
        p.recipient.transfer(p.amount);

        emit ProposalExecuted(_proposalId);
    }

    // Allow contract to receive Ether
    receive() external payable {}
}
