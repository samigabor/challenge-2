// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IStaking {
    function getStake(address token, address account) external view returns (uint256);
    function isStakeLocked(address token, address account) external view returns (bool);
    
    function lockStake(address token, address account, uint256 duration) external;
}
