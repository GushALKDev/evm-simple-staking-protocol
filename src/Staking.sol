// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "forge-std/console.sol"; // Import console for debugging

contract Staking is Ownable, ReentrancyGuard {

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error Staking__ZeroAmount();
    error Staking__InsufficientBalance();
    error Staking__NoRewardsLeft();
    error Staking__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            INTERFACES
    //////////////////////////////////////////////////////////////*/

    IERC20 public stakingToken;

    /*//////////////////////////////////////////////////////////////
                            STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public s_rewardsPerBlock; // Reward tokens per block
    uint256 public s_lastUpdateBlock; // Last block where rewards were updated
    uint256 public s_rewardPerTokenStored; // Accumulated reward per token
    uint256 public s_maxRewards; // Maximum available rewards
    uint256 private s_totalStaked; // Total tokens staked

    /*//////////////////////////////////////////////////////////////
                            MAPPING VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public s_userRewardPerTokenPaid; // Last reward per token paid to user
    mapping(address => uint256) public s_rewards; // Pending rewards per user
    mapping(address => uint256) public s_balances; // Staked balance per user

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsAdded(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateBlock = block.number;
        if (account != address(0)) {
            s_rewards[account] = earned(account);
            s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _stakingToken, uint256 _rewardRate) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        s_rewardsPerBlock = _rewardRate;
        s_lastUpdateBlock = block.number;
    }

    /*//////////////////////////////////////////////////////////////
                            AUXILIARY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Calculates reward per token at current time
    function rewardPerToken() internal view returns (uint256) {
        if (s_totalStaked == 0) {
            return s_rewardPerTokenStored;
        }
        return s_rewardPerTokenStored + (s_rewardsPerBlock * (block.number - s_lastUpdateBlock) * 1e18 / s_totalStaked);
    }

    // Calculates rewards earned by a specific account
    function earned(address account) internal view returns (uint256) {
        return (s_balances[account] * (rewardPerToken() - s_userRewardPerTokenPaid[account]) / 1e18) + s_rewards[account];
    }

    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Allows users to stake tokens
    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert Staking__ZeroAmount();
        s_totalStaked += amount;
        s_balances[msg.sender] += amount;
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert Staking__TransferFailed();
        emit Staked(msg.sender, amount);
    }

    // Allows users to withdraw their staked tokens
    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert Staking__ZeroAmount();
        if (amount > s_balances[msg.sender]) revert Staking__InsufficientBalance();
        s_totalStaked -= amount;
        s_balances[msg.sender] -= amount;
        bool success = stakingToken.transfer(msg.sender, amount);
        if (!success) revert Staking__TransferFailed();
        emit Withdrawn(msg.sender, amount);
    }

    // Allows users to claim their accumulated rewards
    function getRewards() external nonReentrant updateReward(msg.sender) {
        console.log("[GETTING REWARDS]");
        uint256 reward = s_rewards[msg.sender];
        console.log("Reward to be claimed:", reward/1e18);
        console.log("Rewards left:", s_maxRewards/1e18);
        if (s_maxRewards <= reward) revert Staking__NoRewardsLeft();
        s_maxRewards -= reward;
        if (reward > 0) {
            s_rewards[msg.sender] = 0;
            bool success = stakingToken.transfer(msg.sender, reward);
            if (!success) revert Staking__TransferFailed();
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Allows owner to add more reward tokens to the pool
    function addRewards(uint256 amount) external onlyOwner {
        bool success = stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) revert Staking__TransferFailed();
        s_maxRewards += amount;
        emit RewardsAdded(amount);
    }
}
