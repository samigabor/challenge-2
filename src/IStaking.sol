// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IStaking {
    function getStake(address token, address account) external view returns (uint256);
}
