// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {ForwarderFactory} from "../src/ForwarderFactory.sol";

// solhint-disable private-vars-leading-underscore

contract ForwarderFactoryTest is Test {
    function addr(string memory word) public pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(word)))));
    }

    ForwarderFactory public forwarder;
    address deployer = addr("deployer");
    address parent = addr("parent");

    function setUp() public {
    }
}
