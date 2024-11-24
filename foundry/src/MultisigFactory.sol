// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Multisig.sol";

contract MultisigFactory {
    event MultisigCreated(address indexed creator, address multisigAddress);

    function createMultisig(address superAdmin, address[] memory committee, uint256 threshold) external returns (address) {
        Multisig newMultisig = new Multisig(superAdmin, committee, threshold);
        emit MultisigCreated(msg.sender, address(newMultisig));
        return address(newMultisig);
    }
}
