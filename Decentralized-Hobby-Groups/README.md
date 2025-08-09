# Decentralized Hobby Groups Smart Contract

A Clarity smart contract for the Stacks blockchain that enables the creation and management of decentralized hobby groups with shared resource pools and community governance.

## Overview

This smart contract allows users to create interest-based communities where members can pool resources together and make collective decisions about how to spend shared funds through a proposal and voting system.

## Features

- **Group Creation**: Create hobby groups with customizable parameters
- **Membership Management**: Join/leave groups with entry fees
- **Resource Pooling**: Shared funds contributed by all members
- **Governance**: Proposal creation and voting system for spending decisions
- **Reputation System**: Track member contributions and build reputation
- **Flexible Configuration**: Customizable group sizes, entry fees, and categories

## Contract Structure

### Data Maps

- `groups`: Stores group information including name, description, member count, and resource pool
- `memberships`: Tracks individual member data within groups
- `proposals`: Manages spending proposals for groups
- `votes`: Records individual votes on proposals

### Key Functions

#### Group Management
- `create-group`: Create a new hobby group
- `join-group`: Join an existing group by paying entry fee
- `leave-group`: Leave a group (deactivates membership)

#### Resource Management
- `contribute-to-pool`: Add additional funds to group resource pool
- `create-proposal`: Propose spending from group funds
- `vote-on-proposal`: Vote on spending proposals
- `execute-proposal`: Execute approved proposals

#### Read-Only Functions
- `get-group`: Retrieve group information
- `get-membership`: Get membership details
- `is-member`: Check if user is a group member
- `get-proposal`: Retrieve proposal information

## Usage Examples

### Creating a Group

```clarity
(contract-call? .hobby-groups create-group 
  "Photography Enthusiasts" 
  "A group for photographers to share resources and organize photo walks" 
  "Photography" 
  u50 
  u1000000) ;; 1 STX entry fee
```

### Joining a Group

```clarity
(contract-call? .hobby-groups join-group u1)
```

### Contributing to Resource Pool

```clarity
(contract-call? .hobby-groups contribute-to-pool u1 u500000) ;; 0.5 STX
```

### Creating a Spending Proposal

```clarity
(contract-call? .hobby-groups create-proposal 
  u1 
  "Buy Camera Equipment" 
  "Purchase shared camera equipment for group photo sessions" 
  u5000000 ;; 5 STX
  'SP1234...RECIPIENT)
```

### Voting on Proposals

```clarity
(contract-call? .hobby-groups vote-on-proposal u1 true) ;; Vote in favor
```

## Error Codes

| Code | Description |
|------|-------------|
| u400 | Invalid amount |
| u401 | Unauthorized |
| u402 | Insufficient funds |
| u403 | Not a member |
| u404 | Group not found |
| u405 | Proposal not found |
| u409 | Already a member |
| u410 | Already voted |
| u429 | Group full |

## Security Features

- **Access Control**: Only group members can create proposals and vote
- **Fund Safety**: Funds are held securely in the contract
- **Time Limits**: Proposals have expiration times
- **Vote Verification**: Prevents double voting
- **Balance Checks**: Ensures sufficient funds before transfers

## Governance Model

The contract implements a simple majority voting system:
1. Any group member can create spending proposals
2. Proposals are active for 144 blocks (~24 hours)
3. All group members can vote once per proposal
4. Proposals require more "for" votes than "against" votes
5. Approved proposals can be executed after voting period ends

## Member Reputation

Members build reputation through:
- Initial reputation upon joining (50 points)
- Bonus reputation for group creators (100 points)
- Additional reputation for contributions (1 point per 1000 µSTX contributed)

## Deployment

1. Deploy the contract to Stacks blockchain
2. The contract deployer becomes the `CONTRACT_OWNER`
3. Users can immediately start creating and joining groups

## Development

### Requirements
- Clarity 2.0
- Stacks blockchain
- STX tokens for transactions

### Testing
Run comprehensive tests covering:
- Group creation and management
- Membership operations
- Resource pooling
- Proposal lifecycle
- Error conditions

## Future Enhancements

- Multi-token support (SIP-010 tokens)
- Advanced reputation algorithms
- Group categories with special features
- Integration with external APIs
- Mobile app interface
- Advanced governance mechanisms

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit pull request with detailed description

## License

MIT License - see LICENSE file for details.

## Support

For questions and support, please create an issue in the repository or contact the development team.