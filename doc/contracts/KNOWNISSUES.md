# Overview

This document outlines known issues in the codebase.

1. governance is trusted. If any admin goes rogue it can brick the entire system and steal all funds.
2. If core sets global reentrancy lock to invalid lock, the entire system is frozen until this value is set back to a valid lock.
3. If admin sets pointer to Core on CoreRef to an invalid core contract, the contract is frozen forever and will not be recoverable as ACL rules will not work.
4. If admin does emergency pause, the entire system that uses global reentrancy locks is frozen until the admin unpauses it.
5. EmergencyAction allows the admin to execute any action on any contract. If the admin goes rogue, they can steal all funds as well as brick the GlobalReentrancyLock by calling lock and not unlocking.
6. If a user makes a purchase from the internal AMM and pays in ETH, an emergency arises and funds need to be pulled from the AMM, the raw ETH cannot be immediately pulled and wrapEth must be called before funds can be pulled.
7. The internal AMM must be correctly configured to have WETH as the underlying for pairs that use ETH as the quote asset. If this is not done, the AMM will not work correctly as users will not be able to purchase tokens with raw eth due to failing check.
8. Admin is admin of admin in Core, which means that it can add and revoke itself and others with this role.
9. `withdrawERC20` in ERC1155Sale breaks internal accounting and is only to be used in an emergency.