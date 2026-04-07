// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Test, console} from "forge-std/Test.sol";
import {V4HooksStoreRegistry} from "../src/V4HooksStoreRegistry.sol";
import {ISubHookRegistry, PoolHookConfig, ConflictStrategy} from "../src/ISubHookRegistry.sol";

contract MockSubHookRegistry is ISubHookRegistry {
    PoolHookConfig private _config;

    function setPoolConfig(PoolHookConfig calldata config) external {
        _config = config;
    }

    function getPoolConfig(bytes32) external view returns (PoolHookConfig memory) {
        return _config;
    }

    function getSubHooks(bytes32) external view returns (address[] memory) {
        return new address[](0);
    }

    function subHookCount(bytes32) external view returns (uint256) {
        return 0;
    }

    function isRegistered(bytes32, address) external view returns (bool) {
        return false;
    }
}

contract V4HooksStoreRegistryTest is Test {
    V4HooksStoreRegistry public registry;
    MockSubHookRegistry public mockSuperHook;

    address internal owner = address(0x1);
    address internal user = address(0x2);
    address internal subHook1 = address(0x10);
    address internal subHook2 = address(0x11);
    address internal subHook3 = address(0x12);

    bytes32 internal poolId1 = bytes32(uint256(1));
    bytes32 internal poolId2 = bytes32(uint256(2));
    bytes32 internal poolId3 = bytes32(uint256(3));

    function setUp() public {
        vm.prank(owner);
        mockSuperHook = new MockSubHookRegistry();
        vm.prank(owner);
        registry = new V4HooksStoreRegistry(mockSuperHook);
    }

    function test_constructor_setsSuperHook() public {
        assertEq(address(registry.owner()), owner);
    }

    function test_registerSubHook_success() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit V4HooksStoreRegistry.SubHookRegistered(subHook1);
        registry.registerSubHook(subHook1, "ipfs://metadata1");

        (string memory metadata, uint256 registeredAt) = registry.registryEntries(subHook1);
        assertEq(metadata, "ipfs://metadata1");
        assertEq(registeredAt, block.timestamp);
        assertEq(registry.getRegisteredSubhooksCount(), 1);
    }

    function test_registerSubHook_multiple() public {
        vm.prank(owner);
        registry.registerSubHook(subHook1, "meta1");

        vm.prank(owner);
        registry.registerSubHook(subHook2, "meta2");

        vm.prank(owner);
        registry.registerSubHook(subHook3, "meta3");

        assertEq(registry.getRegisteredSubhooksCount(), 3);

        address[] memory all = registry.getAllRegisteredSubhooks();
        assertEq(all[0], subHook1);
        assertEq(all[1], subHook2);
        assertEq(all[2], subHook3);
    }

    function test_registerSubHook_revert_notOwner() public {
        vm.prank(user);
        vm.expectRevert(); // OwnableUnauthorizedAccount revert
        registry.registerSubHook(subHook1, "meta");
    }

    function test_markAsSuperHookEnabled_success() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);

        assertEq(registry.getSuperHookEnabledPoolsCount(), 1);

        bytes32[] memory pools = registry.getAllSuperHookEnabledPools();
        assertEq(pools[0], poolId1);
    }

    function test_markAsSuperHookEnabled_multiple() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);
        registry.markAsSuperHookEnabled(poolId2);
        registry.markAsSuperHookEnabled(poolId3);

        assertEq(registry.getSuperHookEnabledPoolsCount(), 3);
    }

    function test_markAsSuperHookEnabled_revert_notEnabled() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        vm.expectRevert(abi.encodeWithSignature("NotSuperHookEnabled(bytes32)", poolId1));
        registry.markAsSuperHookEnabled(poolId1);
    }

    function test_getRegisteredSubhooksCount_empty() public {
        assertEq(registry.getRegisteredSubhooksCount(), 0);
    }

    function test_getAllRegisteredSubhooks_empty() public {
        address[] memory result = registry.getAllRegisteredSubhooks();
        assertEq(result.length, 0);
    }

    function test_getAllRegisteredSubhooks_withData() public {
        vm.prank(owner);
        registry.registerSubHook(subHook1, "meta");
        vm.prank(owner);
        registry.registerSubHook(subHook2, "meta");

        address[] memory result = registry.getAllRegisteredSubhooks();
        assertEq(result.length, 2);
        assertEq(result[0], subHook1);
        assertEq(result[1], subHook2);
    }

    function test_getRegisteredSubhooks_offsetExceedsLength() public {
        vm.prank(owner);
        registry.registerSubHook(subHook1, "meta");

        address[] memory result = registry.getRegisteredSubhooks(5, 10);
        assertEq(result.length, 0);
    }

    function test_getRegisteredSubhooks_countZero() public {
        vm.prank(owner);
        registry.registerSubHook(subHook1, "meta");

        address[] memory result = registry.getRegisteredSubhooks(0, 0);
        assertEq(result.length, 0);
    }

    function test_getRegisteredSubhooks_fullPage() public {
        vm.prank(owner);
        registry.registerSubHook(subHook1, "meta1");
        vm.prank(owner);
        registry.registerSubHook(subHook2, "meta2");
        vm.prank(owner);
        registry.registerSubHook(subHook3, "meta3");

        address[] memory result = registry.getRegisteredSubhooks(0, 2);
        assertEq(result.length, 2);
        assertEq(result[0], subHook1);
        assertEq(result[1], subHook2);
    }

    function test_getRegisteredSubhooks_partialPage() public {
        vm.prank(owner);
        registry.registerSubHook(subHook1, "meta1");
        vm.prank(owner);
        registry.registerSubHook(subHook2, "meta2");
        vm.prank(owner);
        registry.registerSubHook(subHook3, "meta3");

        address[] memory result = registry.getRegisteredSubhooks(1, 10);
        assertEq(result.length, 2);
        assertEq(result[0], subHook2);
        assertEq(result[1], subHook3);
    }

    function test_getRegisteredSubhooks_middleOffset() public {
        vm.prank(owner);
        registry.registerSubHook(subHook1, "meta1");
        vm.prank(owner);
        registry.registerSubHook(subHook2, "meta2");
        vm.prank(owner);
        registry.registerSubHook(subHook3, "meta3");

        address[] memory result = registry.getRegisteredSubhooks(2, 1);
        assertEq(result.length, 1);
        assertEq(result[0], subHook3);
    }

    function test_getSuperHookEnabledPoolsCount_empty() public {
        assertEq(registry.getSuperHookEnabledPoolsCount(), 0);
    }

    function test_getAllSuperHookEnabledPools_empty() public {
        bytes32[] memory result = registry.getAllSuperHookEnabledPools();
        assertEq(result.length, 0);
    }

    function test_getAllSuperHookEnabledPools_withData() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);
        registry.markAsSuperHookEnabled(poolId2);

        bytes32[] memory result = registry.getAllSuperHookEnabledPools();
        assertEq(result.length, 2);
        assertEq(result[0], poolId1);
        assertEq(result[1], poolId2);
    }

    function test_getSuperHookEnabledPools_offsetExceedsLength() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);

        bytes32[] memory result = registry.getSuperHookEnabledPools(5, 10);
        assertEq(result.length, 0);
    }

    function test_getSuperHookEnabledPools_countZero() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);

        bytes32[] memory result = registry.getSuperHookEnabledPools(0, 0);
        assertEq(result.length, 0);
    }

    function test_getSuperHookEnabledPools_fullPage() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);
        registry.markAsSuperHookEnabled(poolId2);
        registry.markAsSuperHookEnabled(poolId3);

        bytes32[] memory result = registry.getSuperHookEnabledPools(0, 2);
        assertEq(result.length, 2);
        assertEq(result[0], poolId1);
        assertEq(result[1], poolId2);
    }

    function test_getSuperHookEnabledPools_partialPage() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);
        registry.markAsSuperHookEnabled(poolId2);
        registry.markAsSuperHookEnabled(poolId3);

        bytes32[] memory result = registry.getSuperHookEnabledPools(1, 10);
        assertEq(result.length, 2);
        assertEq(result[0], poolId2);
        assertEq(result[1], poolId3);
    }

    function test_getSuperHookEnabledPools_middleOffset() public {
        PoolHookConfig memory config = PoolHookConfig({
            subHooks: new address[](0),
            strategy: ConflictStrategy.FIRST_WINS,
            customResolver: address(0),
            admin: address(0x5),
            locked: false
        });
        mockSuperHook.setPoolConfig(config);

        registry.markAsSuperHookEnabled(poolId1);
        registry.markAsSuperHookEnabled(poolId2);
        registry.markAsSuperHookEnabled(poolId3);

        bytes32[] memory result = registry.getSuperHookEnabledPools(2, 1);
        assertEq(result.length, 1);
        assertEq(result[0], poolId3);
    }
}