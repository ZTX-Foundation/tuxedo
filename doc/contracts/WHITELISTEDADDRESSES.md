# WhitelistedAddresses Contract Documentation

The `WhitelistedAddresses` contract provides functionality to manage a set of whitelisted addresses. It allows adding and removing addresses from the whitelist and provides a modifier to restrict access to only whitelisted addresses.

#### Roles
No specific roles are required to interact with the `WhitelistedAddresses` contract.

#### Events
1. `WhitelistAddressAdded`: Emits when an address is added to the whitelist.
   - Parameters:
     - `address`: The address that was added to the whitelist.

2. `WhitelistAddressRemoved`: Emits when an address is removed from the whitelist.
   - Parameters:
     - `address`: The address that was removed from the whitelist.

#### Storage Variables
- `whitelistedAddresses`: A set of whitelisted addresses stored using the `EnumerableSet.AddressSet` from OpenZeppelin.

#### Functions
- `onlyWhitelist`: Modifier that restricts access to only whitelisted addresses.
- `_addWhitelistAddress`: Adds an address to the whitelist.
- `_removeWhitelistAddress`: Removes an address from the whitelist.
- `_addWhitelistAddresses`: Adds multiple addresses to the whitelist.
- `_removeWhitelistAddresses`: Removes multiple addresses from the whitelist.
- `isWhitelistedAddress`: Checks if an address is whitelisted.
- `getWhitelistedAddresses`: Returns an array of all whitelisted addresses.