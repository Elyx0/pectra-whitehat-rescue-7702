// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

contract RandomSmartAccount {

    event Received(address indexed sender, uint256 amount);
    event Fallback(address indexed sender, uint256 amount);
    event Rescued();

    constructor() {
        // Will never be called
    }

    fallback() external payable {
        emit Fallback(msg.sender, msg.value);
    }
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function rescue() external {
        block.coinbase.call{value: 0.0001 ether}("");
        emit Rescued();
    }
}

// Deploy me with:
// forge create src/RandomSmartAccount.sol:RandomSmartAccount --rpc-url $SEPOLIA_RPC_URL --private-key $SEPOLIA_PRIVATE_KEY