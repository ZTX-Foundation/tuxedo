import { ethers } from 'ethers';

const message = `Welcome to ZTX! Click sign to authenticate and login to ZTX. This request will not trigger a blockchain transaction or cost any gas fees. Your authentication status will reset every time you visit ztx.io. `

const signerAddress = ethers.utils.verifyMessage(
    message,
    ethers.utils.splitSignature('0x49601031d74b63ea49ca8c9c1e85d88208e18cdf819d3d443eb41b2ca5cf40e07e477437f6259518a99b743490c9a250c9cba6aeb2921358c7cd13a661cdf5631c')
);

console.log(signerAddress);
