// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";

contract StakingScript is Script {
    Staking public staking;

    constructor() {
    }

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the staking contract
        staking = new Staking(0xdAC17F958D2ee523a2206206994597C13D831ec7, 1e18);

        vm.stopBroadcast();
    }
}
