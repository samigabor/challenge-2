// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStaking.sol";

contract Staking is Initializable, AccessControlUpgradeable, UUPSUpgradeable, IStaking {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    mapping(address => bool) public tokens;
    mapping(address token => mapping(address staker => uint256)) private balances;
    mapping(address token => mapping(address staker => uint256)) private lockedUntil;

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);

    error Staking__ZeroNotAllowed();
    error Staking__InsuficientBalance();
    error Staking__NotRegistered(address token);
    error Staking__InvalidLockDate();

    modifier onlyRegisteredToken(address token) {
        if (!tokens[token]) revert Staking__NotRegistered(token);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address upgrader)
        initializer public
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    /**
     * Whitelist a token for staking.
     * @param token The token to register.
     */
    function registerToken(address token) external onlyRole(ADMIN_ROLE) {
        tokens[token] = true;
    }

    /**
     * Stake `amount` tokens from the caller.
     * @param token The token to stake.
     * @param amount The amount to stake.
     */
    function stake(address token, uint256 amount) external {
        if (amount == 0) revert Staking__ZeroNotAllowed();
        balances[token][msg.sender] += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /**
     * Unstake `amount` tokens for the caller.
     * @param token The token to unstake.
     * @param amount The amount to unstake.
     */
    function unstake(address token, uint256 amount) external {
        if (balances[token][msg.sender] < amount) revert Staking__InsuficientBalance();
        balances[token][msg.sender] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
     * Lock the stake of an account until a given date. Locking mechanism guards against double voting on a survey.
     * Only Survey contract should have the LOCKER_ROLE.
     * @param token The token to lock
     * @param account The account to lock
     * @param until The timestamp until the stake is locked
     */
    function lockStake(address token, address account, uint256 until) public onlyRole(LOCKER_ROLE) {
        if (until < block.timestamp) revert Staking__InvalidLockDate();
        lockedUntil[token][account] = until;
    }

    /**
     * Check if the stake of an account is locked
     * @param token The token to check
     * @param account The account to check
     * @return True if the stake is locked, false otherwise
     */
    function isStakeLocked(address token, address account) public view returns (bool) {
        return lockedUntil[token][account] > block.timestamp;
    }

    /**
     * Get the stake of a particular token for a given account
     * @param token The token staked
     * @param account The address of the staker
     * @return The amount staked
     */
    function getStake(address token, address account) public view returns (uint256) {
        return balances[token][account];
    }
}
