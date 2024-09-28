// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;
import './Forwarder.sol';
import './CloneFactory.sol';

contract ForwarderFactory is CloneFactory {
  address public implementationAddress;

  event ForwarderCreated(
    address newForwarderAddress,
    address parentAddress,
    address adminAddress,
    bool shouldAutoFlushNative,
    bool shouldAutoFlushERC721,
    bool shouldAutoFlushERC1155
  );

  constructor(address _implementationAddress) {
    implementationAddress = _implementationAddress;
  }

  function createForwarder(address parent, address admin, bytes32 salt) external {
    this.createForwarder(parent, admin, salt, true, true, true);
  }

  function createForwarder(
    address parent,
    address admin,
    bytes32 salt,
    bool shouldAutoFlushNative,
    bool shouldAutoFlushERC721,
    bool shouldAutoFlushERC1155
  ) external {
    // include the signers in the salt so any contract deployed to a given address must have the same signers
    bytes32 finalSalt = keccak256(abi.encodePacked(parent, salt));

    address payable clone = createClone(implementationAddress, finalSalt);
    Forwarder(clone).init(
      parent,
      admin,
      shouldAutoFlushNative,
      shouldAutoFlushERC721,
      shouldAutoFlushERC1155
    );
    emit ForwarderCreated(
      clone,
      parent,
      admin,
      shouldAutoFlushNative,
      shouldAutoFlushERC721,
      shouldAutoFlushERC1155
    );
  }
}