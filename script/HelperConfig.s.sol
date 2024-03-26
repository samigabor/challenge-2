// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

contract HelperConfig is Script {

    struct Config {
        uint256 deployKey;
        address deployer;
        address upgrader;
        address admin;
    }

    uint256 public constant ANVIL_KEY_0 = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address public constant ANVIL_ADDRESS_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant ANVIL_ADDRESS_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public constant ANVIL_ADDRESS_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    Config public config;

    constructor() {
        if (block.chainid == 31337) {
            console.log("Anvil chain: ", block.chainid);
            config = Config({
                deployKey: ANVIL_KEY_0,
                deployer: ANVIL_ADDRESS_0,
                upgrader: ANVIL_ADDRESS_1,
                admin: ANVIL_ADDRESS_2
            });
        } else {
            console.log("Livenet chain: ", block.chainid);
            config = Config({
                deployKey: vm.envUint("PRIVATE_KEY"),
                deployer: vm.envAddress("DEPLOYER"),
                upgrader: vm.envAddress("UPGRADER"),
                admin: vm.envAddress("ADMIN")
            });
        }
    }
}
