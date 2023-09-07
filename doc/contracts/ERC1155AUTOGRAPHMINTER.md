# ERC1155AutoGraphMinter Contract Documentation

## Contract Overview

The `ERC1155AutoGraphMinter` contract provides a rate-limiting mechanism to control the speed at which certain actions can be performed. It allows setting a rate per second and a buffer cap to regulate the usage of the action.

## Roles

-   `TOKEN_GOVERNOR`: Role required to set the replenish rate per second and the buffer cap.
-   `ADMIN`: Role required to set the replenish rate per second and the buffer cap.
-   `MINTER`: Role required to mint tokens.
-   `LOCKER`: Role that is required to use the global reentrancy lock.

## Events

1. `BufferUsed`: Emits when the buffer is consumed by an action.

    - Parameters:
        - `amountUsed`: The amount consumed from the buffer.
        - `bufferRemaining`: The remaining buffer after the consumption.

2. `BufferReplenished`: Emits when the buffer is replenished.

    - Parameters:
        - `amountReplenished`: The amount replenished into the buffer.
        - `bufferRemaining`: The remaining buffer after the replenishment.

3. `BufferCapUpdate`: Emits when the buffer cap is updated.

    - Parameters:
        - `oldBufferCap`: The previous buffer cap value.
        - `newBufferCap`: The new buffer cap value.

4. `ReplenishRatePerSecondUpdate`: Emits when the replenish rate per second is updated.
    - Parameters:
        - `oldReplenishRatePerSecond`: The previous replenish rate per second value.
        - `newRateReplenishPerSecond`: The new replenish rate per second value.

## Storage Variables

-   `replenishRatePerSecond`: The rate per second at which the buffer is replenished.
-   `bufferCap`: The maximum capacity of the buffer.
-   `lastBufferUsedTime`: The timestamp of the last buffer usage.
-   `bufferRemaining`: The remaining buffer amount at the timestamp of the last buffer usage.

### Functions

-   `setReplenishRatePerSecond`: Sets the rate per second at which the buffer is replenished.
-   `setBufferCap`: Sets the maximum capacity of the buffer.
-   `buffer`: Returns the amount of action available in the buffer.

The following functions are internal and are not meant to be called directly (child contracts must call to deplete or replenish):

-   `_depleteBuffer`: Decreases the buffer by a specified amount, enforcing the rate limit.
-   `_setReplenishRatePerSecond`: Updates the replenish rate per second.
-   `_setBufferCap`: Updates the buffer cap.
-   `_updateBufferRemaining`: Updates the remaining buffer amount based on the current timestamp.
