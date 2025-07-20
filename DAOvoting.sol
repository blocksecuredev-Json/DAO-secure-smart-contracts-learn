// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract DAOVoting {
    struct Proposal {
        string description;            // What the proposal is about
        uint startTime;                // When voting starts
        uint endTime;                  // When voting ends
        uint timelock;                 // How long to wait after endTime before execution
        uint yesVotes;                 // Number of yes votes
        uint noVotes;                  // Number of no votes
        bool executed;                 // Whether proposal has been executed
        bool canceled;                 // Whether proposal was canceled
        mapping(address => bool) hasVoted;  // Who has voted already and This is used inside the proposal struct to specialize in each proposal created
    }

    mapping(uint => Proposal) public proposals; // Store all proposals
    uint public proposalCount;                  // Count of proposals

    event ProposalCreated(uint id, string description, uint startTime, uint endTime, uint timelock); // This is an event for proposal created
    event Voted(uint id, address voter, bool support); // this is an event for votes description and voters
    event ProposalExecuted(uint id); // An event for proposal executed shwoing the information
    event ProposalCanceled(uint id);  // Also an event for proposal cancelled

    modifier proposalExists(uint _id) {
        require(_id < proposalCount, "Proposal does not exist"); // here the proposal created must be less than the number of proposals or else it will throw an exception 
        _;
    }

    modifier onlyDuringVoting(uint _id) {
        require(
            block.timestamp >= proposals[_id].startTime &&  // here this checks if the current time i.e block.timestamp is within the voting period
            block.timestamp <= proposals[_id].endTime,
            "Voting not active"
        );
        _;
    }

    modifier onlyAfterDeadline(uint _id) {
        require(block.timestamp > proposals[_id].endTime, "Voting still ongoing");  // this ensures that the proposal voting has ended i.e the current time is greater than the end
        _;
    }

    modifier onlyAfterTimelock(uint _id) {
        require(
            block.timestamp >= proposals[_id].endTime + proposals[_id].timelock, // this ensures a delayed execution after voting has eneded i.e the current time is greater than the end time plus the timel
            "Timelock not passed"
        );
        _;
    }

    function createProposal(
        string memory _description,
        uint _startDelay,          // Delay in seconds before voting starts
        uint _duration,            // How long voting lasts (in seconds)
        uint _timelock             // Timelock after voting ends
    ) external {
        Proposal storage p = proposals[proposalCount];
        p.description = _description;
        p.startTime = block.timestamp + _startDelay;
        p.endTime = p.startTime + _duration;
        p.timelock = _timelock;

        emit ProposalCreated(proposalCount, _description, p.startTime, p.endTime, _timelock);
        proposalCount++;
    }

    function vote(uint _id, bool _support)
        external
        proposalExists(_id)
        onlyDuringVoting(_id)
    {
        Proposal storage p = proposals[_id];
        require(!p.hasVoted[msg.sender], "Already voted");
        require(!p.canceled, "Proposal canceled");

        if (_support) {
            p.yesVotes++;
        } else {
            p.noVotes++;
        }

        p.hasVoted[msg.sender] = true;
        emit Voted(_id, msg.sender, _support);
    }

    function executeProposal(uint _id)
        external
        proposalExists(_id)
        onlyAfterDeadline(_id)
        onlyAfterTimelock(_id)
    {
        Proposal storage p = proposals[_id];
        require(!p.executed, "Already executed");
        require(!p.canceled, "Proposal canceled");
        require(p.yesVotes > p.noVotes, "Proposal not approved");

        p.executed = true;
        emit ProposalExecuted(_id);
        
    }

    function cancelProposal(uint _id) external proposalExists(_id) {
        Proposal storage p = proposals[_id];
        require(block.timestamp < p.startTime, "Voting already started");
        require(!p.canceled, "Already canceled");

        p.canceled = true;
        emit ProposalCanceled(_id);
    }
}
