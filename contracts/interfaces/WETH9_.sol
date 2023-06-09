// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface WETH9_ {
    function deposit() external payable;

    function withdraw(uint wad) external;
}