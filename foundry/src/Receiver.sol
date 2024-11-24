// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Receiver {
    // List of recipient addresses and their respective percentages
    address[] public recipients;
    uint256[] public percentages; // Percentages in basis points (10000 = 100%)

    event FundFlushed(address indexed from, uint256 value, address indexed recipient, uint256 share);
    event TokenFlushed(address indexed token, uint256 total, address indexed recipient, uint256 share);

    /**
     * @dev Initializes the recipients and their percentages.
     * @param _recipients List of recipient addresses.
     * @param _percentages Corresponding percentages in basis points.
     */
    constructor(address[] memory _recipients, uint256[] memory _percentages) {
        require(_recipients.length == _percentages.length, "Mismatched arrays");
        require(_validatePercentages(_percentages), "Percentages must sum to 10000");

        recipients = _recipients;
        percentages = _percentages;
    }

    /**
     * @dev Receive native Ether and distribute it to recipients immediately.
     */
    receive() external payable {
        uint256 totalReceived = msg.value;
        require(totalReceived > 0, "No Ether received");

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 share = (totalReceived * percentages[i]) / 10000; // Calculate recipient's share
            (bool success, ) = recipients[i].call{value: share}("");
            require(success, "Ether flush failed");
            emit FundFlushed(msg.sender, share, recipients[i], share);
        }
    }

    /**
     * @dev Flush ERC20 tokens to recipients immediately.
     * @param tokenContractAddress The address of the ERC20 token contract.
     */
    function flushTokens(address tokenContractAddress) external {
        IERC20 token = IERC20(tokenContractAddress);
        uint256 totalBalance = token.balanceOf(address(this));
        require(totalBalance > 0, "No tokens to flush");

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 share = (totalBalance * percentages[i]) / 10000; // Calculate recipient's share
            require(token.transfer(recipients[i], share), "Token transfer failed");
            emit TokenFlushed(tokenContractAddress, share, recipients[i], share);
        }
    }

    /**
     * @dev Updates the list of recipients and percentages.
     * @param _recipients List of new recipient addresses.
     * @param _percentages Corresponding new percentages in basis points.
     */
    function updateRecipients(address[] calldata _recipients, uint256[] calldata _percentages) external {
        require(_recipients.length == _percentages.length, "Mismatched arrays");
        require(_validatePercentages(_percentages), "Percentages must sum to 10000");

        recipients = _recipients;
        percentages = _percentages;
    }

    /**
     * @dev Validates that percentages sum to 10000 (100%).
     * @param _percentages The array of percentages to validate.
     * @return True if the percentages sum to 10000, false otherwise.
     */
    function _validatePercentages(uint256[] memory _percentages) internal pure returns (bool) {
        uint256 total = 0;
        for (uint256 i = 0; i < _percentages.length; i++) {
            total += _percentages[i];
        }
        return total == 10000;
    }
}
