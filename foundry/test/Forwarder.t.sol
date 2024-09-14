// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {Forwarder} from "../src/Forwarder.sol";

// solhint-disable private-vars-leading-underscore

contract ForwarderTest is Test {

    function addr(string memory word) public pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(word)))));
    }

    Forwarder public forwarder;
    address deployer = addr("deployer");
    address parent = addr("parent");

    function setUp() public {
        forwarder = new Forwarder();
    }

    function testInitSuccess() public {
        vm.prank(deployer);
        forwarder.init(parent, true, true);

        address expected = parent;
        address actual = forwarder.parentAddress();
        assertEq(expected, actual, "Addresses should match");
    }

    function testInitFailByInitZeroAddress() public {
        assert(false);
    }

    function testFlushSuccess() public {
        assert(false);
    }
}
