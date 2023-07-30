// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.19;

interface IDestinationPool {
    function receiveFlowMessage(address, int96, uint256, uint256) external;

    function receiveRebalanceMessage() external;
}
