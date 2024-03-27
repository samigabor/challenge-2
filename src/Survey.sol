// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IStaking.sol";

contract Survey is Initializable, AccessControlUpgradeable, UUPSUpgradeable {

    struct SurveyDetails {
        address token;
        string question;
        uint256 expiration;
        uint256 votes;
        bool exists;
    }

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IStaking public stakingContract;
    mapping(uint256 => SurveyDetails) public surveys;
    uint256 public surveyCount;

    event Created(uint256 indexed surveyId, string question, address token);
    event Voted(uint256 indexed surveyId, address indexed voter, uint256 votingPower);

    error Survey__NotStaked(address token, address staker);
    error Survey__NotFound(uint256 surveyId);
    error Survey__AlreadyVoted(uint256 surveyId, address voter);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address upgrader, address admin, address stakingContractAddress)
        initializer public
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
        _grantRole(ADMIN_ROLE, admin);

        stakingContract = IStaking(stakingContractAddress);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    /**
     * Create a new survey.
     * @param token The token linked to the survey.
     * @param question The question to ask.
     * @param expiration The date until voting for the survey is allowed.
     * @return The survey id.
     */
    function create(address token, string memory question, uint256 expiration) external onlyRole(ADMIN_ROLE) returns (uint256) {
        uint256 count = ++surveyCount;
        surveys[count] = SurveyDetails({
            token: token,
            question: question,
            expiration: expiration,
            votes: 0,
            exists: true
        });
        emit Created(count, question, token);
        return count;
    }

    /**
     * Vote on a survey. Voting power is proportional to the staked amount.
     * @param surveyId The survey id.
     */
    function vote(uint256 surveyId) external {
        SurveyDetails memory survey = surveys[surveyId];
        if (!survey.exists) revert Survey__NotFound(surveyId);
        
        uint256 stakedAmount = stakingContract.getStake(survey.token, msg.sender);
        if (stakedAmount == 0) revert Survey__NotStaked(survey.token, msg.sender);

        bool voted = stakingContract.isStakeLocked(survey.token, msg.sender);
        if (voted) revert Survey__AlreadyVoted(surveyId, msg.sender);

        surveys[surveyId].votes += stakedAmount;
        stakingContract.lockStake(survey.token, msg.sender, survey.expiration);
        emit Voted(surveyId, msg.sender, stakedAmount);
    }

    /**
     * Get the votes of a survey.
     * @param surveyId The survey id.
     * @return The number of votes.
     */
    function getVotes(uint256 surveyId) external view returns (uint256) {
        SurveyDetails memory survey = surveys[surveyId];
        if (!survey.exists) revert Survey__NotFound(surveyId);
        return survey.votes;
    }
}
