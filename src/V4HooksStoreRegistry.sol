// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PoolHookConfig,ISubHookRegistry} from "./ISubHookRegistry.sol";

contract V4HooksStoreRegistry is Ownable {
    struct RegistryEntry {
        string metadataUri;
        uint256 registeredAt;
    }

    event SubHookRegistered(address indexed subHook);

    error NotSuperHookEnabled(bytes32 poolId);

    ISubHookRegistry immutable superHook;

    mapping(address => RegistryEntry) public registryEntries;

    address[] public registeredSubhooks;

    bytes32[] public superHookEnabledPools;

    constructor(ISubHookRegistry _superHook) Ownable(msg.sender) {
        superHook = _superHook;
    }

    function registerSubHook(
        address subHook,
        string calldata metadataUri
    ) external onlyOwner {
        registryEntries[subHook] = RegistryEntry({
            metadataUri: metadataUri,
            registeredAt: block.timestamp
        });

        registeredSubhooks.push(subHook);

        emit SubHookRegistered(subHook);
    }

    function markAsSuperHookEnabled(bytes32 poolId) external {
        PoolHookConfig memory cfg = superHook.getPoolConfig(poolId);
        if (cfg.admin == address(0)) {
            revert NotSuperHookEnabled(poolId);
        }

        superHookEnabledPools.push(poolId);
    }

    function getRegisteredSubhooksCount() external view returns (uint256) {
        return registeredSubhooks.length;
    }

    function getAllRegisteredSubhooks() external view returns (address[] memory) {
        return registeredSubhooks;
    }

    function getRegisteredSubhooks(uint256 offset, uint256 count) external view returns (address[] memory) {
        uint256 length = registeredSubhooks.length;
        if (offset >= length) {
            return new address[](0);
        }

        uint256 resultCount = count;
        if (offset + count > length) {
            resultCount = length - offset;
        }

        address[] memory result = new address[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = registeredSubhooks[offset + i];
        }
        return result;
    }

    function getSuperHookEnabledPoolsCount() external view returns (uint256) {
        return superHookEnabledPools.length;
    }

    function getAllSuperHookEnabledPools() external view returns (bytes32[] memory) {
        return superHookEnabledPools;
    }

    function getSuperHookEnabledPools(uint256 offset, uint256 count) external view returns (bytes32[] memory) {
        uint256 length = superHookEnabledPools.length;
        if (offset >= length) {
            return new bytes32[](0);
        }

        uint256 resultCount = count;
        if (offset + count > length) {
            resultCount = length - offset;
        }

        bytes32[] memory result = new bytes32[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = superHookEnabledPools[offset + i];
        }
        return result;
    }
}
