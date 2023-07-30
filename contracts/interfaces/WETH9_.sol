// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface WETH9_ {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}
