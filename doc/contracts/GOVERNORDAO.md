#### GovernorDAO Contract Documentation

The `GovernorDAO` contract is a governance contract that enables voting on proposals within the ZTX protocol. It inherits multiple contracts from the OpenZeppelin library to provide various governance functionalities. The contract requires the CoreRef contract for role management and access control.

#### Roles

To properly function within the system, the `GovernorDAO` contract requires the following roles:

- `TOKEN_GOVERNOR`: The token governor role allows changing voting settings, such as voting delay, voting period, proposal threshold, and quorum.
- `GUARDIAN`: The guardian role allows canceling proposals in progress.

#### Functions

1. `setVotingDelay(uint256 newVotingDelay)`: Sets the voting delay, in blocks, for creating new proposals.

   - Parameters:
     - `newVotingDelay`: The new voting delay to be set.

   - Modifier:
     - `onlyRole(Roles.TOKEN_GOVERNOR)`: Only the token governor role can call this function.

2. `setVotingPeriod(uint256 newVotingPeriod)`: Sets the voting period, in blocks, for active proposals.

   - Parameters:
     - `newVotingPeriod`: The new voting period to be set.

   - Modifier:
     - `onlyRole(Roles.TOKEN_GOVERNOR)`: Only the token governor role can call this function.

3. `setProposalThreshold(uint256 newProposalThreshold)`: Sets the proposal threshold, which represents the minimum number of votes required for a proposal to pass.

   - Parameters:
     - `newProposalThreshold`: The new proposal threshold to be set.

   - Modifier:
     - `onlyRole(Roles.TOKEN_GOVERNOR)`: Only the token governor role can call this function.

4. `setQuorum(uint256 newQuorum)`: Adjusts the quorum, which represents the minimum number of votes needed for a vote to pass.

   - Parameters:
     - `newQuorum`: The new quorum to be set.

   - Modifier:
     - `onlyRole(Roles.TOKEN_GOVERNOR)`: Only the token governor role can call this function.

5. `cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)`: Allows a guardian to cancel a proposal in progress.

   - Parameters:
     - `targets`: The addresses of the targets of the proposal.
     - `values`: The values associated with each target of the proposal.
     - `calldatas`: The calldata associated with each target of the proposal.
     - `descriptionHash`: The hash of the proposal description.

   - Modifier:
     - `onlyRole(Roles.GUARDIAN)`: Only the guardian role can call this function.

#### Events

1. `QuorumUpdated`: Emits when the quorum value is updated.

   - Parameters:
     - `oldQuorum`: The previous quorum value.
     - `newQuorum`: The new quorum value.

These events provide visibility into important changes and updates happening within the `GovernorDAO` contract.

Within the system setup, a timelock is used alongside the `GovernorDAO` contract to introduce an additional layer of security and control over the execution of proposals. The `GovernorDAO` contract is integrated with the `GovernorTimelockControl` contract from the OpenZeppelin library.

The timelock mechanism adds a delay between the proposal's voting period and its execution. When a proposal is created and successfully passes the voting phase, it is queued in the timelock contract for a specific period. During this period, the proposal cannot be executed immediately, providing time for stakeholders to review and potentially veto the proposal if necessary.

After the timelock period has elapsed, the proposal can be executed by calling the `execute` function in the `GovernorDAO` contract. This triggers the execution of the proposed actions, such as updating contract state or performing specific operations.

By incorporating a timelock, the system ensures that there is a predetermined waiting period before executing proposals, allowing for governance transparency and giving stakeholders the opportunity to evaluate and react to proposed changes.
