// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/console.sol";
import "forge-std/Script.sol";

import {V4HooksStoreRegistry} from "../src/V4HooksStoreRegistry.sol";
import {ISubHookRegistry} from "../src/ISubHookRegistry.sol";

contract DeployV4HooksStoreRegistry is Script {

    function run() external {
        console.log("starting V4HooksStoreRegistry deployment...");

        uint256 deployerPrivKey = vm.envUint("KEY");
        vm.startBroadcast(deployerPrivKey);

        address superHook = vm.envAddress("SUPERHOOK");

        V4HooksStoreRegistry registry = new V4HooksStoreRegistry(ISubHookRegistry(superHook));

        console.log("V4 hooks store registry deployed to: ", address(registry));

        vm.stopBroadcast();
    }
}

/* 
Unichain sepolia:
V4 hooks store registry deployed to:  0x085cC909C3890Ad8ba4d12093a101657bf996Ed0
 */
