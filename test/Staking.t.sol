// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "../src/Staking.sol";
import {ERC20Token} from "../src/ERC20Token.sol";

contract StakingTest is Test {

    /*//////////////////////////////////////////////////////////////
                            SETUP TESTS
    //////////////////////////////////////////////////////////////*/

    // Test state variables
    Staking public staking;
    ERC20Token public stakingToken;

    // Test addresses
    address public deployer;
    address public addr1;
    address public addr2;
    address public addr3;
    address public ZERO_ADDRESS = address(0);

    // Constants for testing
    uint256 constant INITIAL_USER_BALANCE = 100_000;
    uint256 constant REWARD_RATE = 1e18;
    uint256 constant INITIAL_REWARDS_POOL = 700_000;

    constructor() {
        deployer = vm.addr(1);
        addr1 = vm.addr(2);
        addr2 = vm.addr(3);
        addr3 = vm.addr(4);
    }

    function setUp() public {
        vm.startPrank(deployer);
        // Deploy the ERC20 token
        stakingToken = new ERC20Token();

        // Distribute tokens
        stakingToken.transfer(addr1, 100_000 * 10 ** stakingToken.decimals());
        stakingToken.transfer(addr2, 100_000 * 10 ** stakingToken.decimals());
        stakingToken.transfer(addr3, 100_000 * 10 ** stakingToken.decimals());

        // Deploy the staking contract
        staking = new Staking(address(stakingToken), 1e18);

        console.log("Staking contract address: ", address(staking));
        console.log("Initial balance of addr1: ", stakingToken.balanceOf(addr1)/1e18);
        console.log("Initial balance of addr2: ", stakingToken.balanceOf(addr2)/1e18);
        console.log("Initial balance of addr3: ", stakingToken.balanceOf(addr3)/1e18);
        vm.stopPrank();
    }
    
    function test_InitialSetup() public view {
        // Verify initial contract state
        assertEq(address(staking.stakingToken()), address(stakingToken));
        assertEq(staking.s_rewardsPerBlock(), REWARD_RATE);
        
        // Verify initial token distributions
        assertEq(stakingToken.balanceOf(addr1), INITIAL_USER_BALANCE * 10 ** stakingToken.decimals());
        assertEq(stakingToken.balanceOf(addr2), INITIAL_USER_BALANCE * 10 ** stakingToken.decimals());
        assertEq(stakingToken.balanceOf(addr3), INITIAL_USER_BALANCE * 10 ** stakingToken.decimals());
    }

    /*//////////////////////////////////////////////////////////////
                            STAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_StakingBasicFlow() public {
        // Setup rewards pool
        _setupRewardsPool();

        // Test staking from addr1
        uint256 stakeAmount = 25_000 * 10 ** stakingToken.decimals();
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();

        assertEq(staking.s_balances(addr1), stakeAmount);
        assertEq(stakingToken.balanceOf(addr1), 75_000 * 10 ** stakingToken.decimals());
    }

    function test_MultipleUsersStaking() public {
        _setupRewardsPool();

        // Multiple users stake different amounts
        uint256[] memory stakeAmounts = new uint256[](3);
        stakeAmounts[0] = 25_000 * 10 ** stakingToken.decimals();
        stakeAmounts[1] = 30_000 * 10 ** stakingToken.decimals();
        stakeAmounts[2] = 45_000 * 10 ** stakingToken.decimals();

        address[] memory users = new address[](3);
        users[0] = addr1;
        users[1] = addr2;
        users[2] = addr3;

        for (uint i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            stakingToken.approve(address(staking), stakeAmounts[i]);
            staking.stake(stakeAmounts[i]);
            vm.stopPrank();
            
            assertEq(staking.s_balances(users[i]), stakeAmounts[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_WithdrawalBasicFlow() public {
        _setupRewardsPool();
        uint256 stakeAmount = 25_000 * 10 ** stakingToken.decimals();
        
        // First stake
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);

        // Then withdraw
        staking.withdraw(stakeAmount);
        vm.stopPrank();

        assertEq(staking.s_balances(addr1), 0);
        assertEq(stakingToken.balanceOf(addr1), INITIAL_USER_BALANCE * 10 ** stakingToken.decimals());
    }

    function test_PartialWithdrawal() public {
        _setupRewardsPool();
        uint256 stakeAmount = 25_000 * 10 ** stakingToken.decimals();
        uint256 withdrawAmount = 10_000 * 10 ** stakingToken.decimals();

        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        staking.withdraw(withdrawAmount);
        vm.stopPrank();

        assertEq(staking.s_balances(addr1), stakeAmount - withdrawAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            REWARDS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RewardAccrual() public {
        _setupRewardsPool();
        uint256 stakeAmount = 25_000 * 10 ** stakingToken.decimals();

        // Stake tokens
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();

        // Advance blocks
        vm.roll(block.number + 100);

        // Check rewards
        vm.prank(addr1);
        staking.getRewards();
        
        assertTrue(stakingToken.balanceOf(addr1) > INITIAL_USER_BALANCE * 10 ** stakingToken.decimals() - stakeAmount);
    }

    function test_MultipleUsersRewards() public {
        _setupRewardsPool();
        uint256 stakeAmount = 25_000 * 10 ** stakingToken.decimals();

        // Two users stake the same amount
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();

        vm.startPrank(addr2);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();

        // Advance blocks
        vm.roll(block.number + 100);

        // Both users claim rewards
        uint256 addr1BalanceBefore = stakingToken.balanceOf(addr1);
        uint256 addr2BalanceBefore = stakingToken.balanceOf(addr2);

        vm.prank(addr1);
        staking.getRewards();
        vm.prank(addr2);
        staking.getRewards();

        // Rewards should be approximately equal
        uint256 addr1Reward = stakingToken.balanceOf(addr1) - addr1BalanceBefore;
        uint256 addr2Reward = stakingToken.balanceOf(addr2) - addr2BalanceBefore;
        assertApproxEqRel(addr1Reward, addr2Reward, 1e16); // 1% tolerance
    }

    /*//////////////////////////////////////////////////////////////
                            EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ZeroStakeAmount() public {
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), 1e18);
        vm.expectRevert(Staking.Staking__ZeroAmount.selector);
        staking.stake(0);
        vm.stopPrank();
    }

    function test_WithdrawMoreThanStaked() public {
        _setupRewardsPool();
        uint256 stakeAmount = 25_000 * 10 ** stakingToken.decimals();

        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        
        vm.expectRevert(Staking.Staking__InsufficientBalance.selector);
        staking.withdraw(stakeAmount + 1);
        vm.stopPrank();
    }

    function test_NoRewardsLeft() public {
        // Setup a very small reward pool
        uint256 smallRewardAmount = 100 * 10 ** stakingToken.decimals();
        vm.startPrank(deployer);
        stakingToken.approve(address(staking), smallRewardAmount);
        staking.addRewards(smallRewardAmount); // Small reward pool
        vm.stopPrank();

        // Stake a moderate amount
        uint256 stakeAmount = 1000 * 10 ** stakingToken.decimals();
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();

        // Advance blocks (enough to generate rewards > smallRewardAmount)
        uint256 blockAdvance = 10;
        vm.roll(block.number + blockAdvance);

        // First claim should work (partial rewards)
        vm.startPrank(addr1);
        staking.getRewards();
        vm.stopPrank();

        // Advance more blocks
        vm.roll(block.number + 100);

        // Second claim should fail due to no rewards left
        vm.startPrank(addr1);
        // IMPORTANT: expectRevert must come BEFORE the call that should revert
        vm.expectRevert(Staking.Staking__NoRewardsLeft.selector);
        staking.getRewards();
        vm.stopPrank();
    }

    // Add new test for arithmetic overflow protection
    function test_RewardCalculationOverflow() public {
        _setupRewardsPool();
        uint256 stakeAmount = 1 * 10 ** stakingToken.decimals(); // Small stake amount

        // First user stakes
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();

        // Try to advance blocks to cause overflow
        uint256 maxBlocks = type(uint256).max;
        vm.roll(maxBlocks);

        // This should revert with arithmetic overflow
        vm.expectRevert();
        staking.getRewards();
    }

    function test_RewardsWithNoStake() public {
        _setupRewardsPool();
        vm.prank(addr1);
        staking.getRewards(); // Should not revert but also should not send any rewards
        assertEq(stakingToken.balanceOf(addr1), INITIAL_USER_BALANCE * 10 ** stakingToken.decimals());
    }

    function test_StakeWithInsufficientBalance() public {
        uint256 excessiveAmount = (INITIAL_USER_BALANCE + 1) * 10 ** stakingToken.decimals();
        
        vm.startPrank(addr1);
        stakingToken.approve(address(staking), excessiveAmount);
        vm.expectRevert(); // Should revert due to insufficient balance
        staking.stake(excessiveAmount);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setupRewardsPool() internal {
        vm.startPrank(deployer);
        stakingToken.approve(address(staking), INITIAL_REWARDS_POOL * 10 ** stakingToken.decimals());
        staking.addRewards(INITIAL_REWARDS_POOL * 10 ** stakingToken.decimals());
        console.log("Initial balance of staking contract: ", stakingToken.balanceOf(address(staking))/1e18);
        vm.stopPrank();
    }
}
