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

    mapping(address => bool) public tokens;
    mapping(address token => mapping(address staker => uint256)) private _balances;

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);

    error Staking__ZeroNotAllowed();
    error Staking__InsuficientBalance();
    error Staking__NotRegistered(address token);

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

    function registerToken(address _token) external onlyRole(ADMIN_ROLE) {
        tokens[_token] = true;
    }

    /**
     * @dev Stake `amount` tokens from the caller.
     * @param token The token to stake.
     * @param amount The amount to stake.
     */
    function stake(address token, uint256 amount) external {
        if (amount == 0) revert Staking__ZeroNotAllowed();
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _balances[token][msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Unstake `amount` tokens from the caller.
     * @param token The token to unstake.
     * @param amount The amount to unstake.
     */
    function unstake(address token, uint256 amount) external {
        if (_balances[token][msg.sender] < amount) revert Staking__InsuficientBalance();
        _balances[token][msg.sender] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
     * @dev Get the stake of a particular token for a given account
     * @param token The token staked
     * @param account The address of the staker
     * @return The amount staked
     */
    function getStake(address token, address account) external view returns (uint256) {
        return _balances[token][account];
    }
}
