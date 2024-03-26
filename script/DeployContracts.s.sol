// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol"; // solhint-disable
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import {Staking} from "../src/Staking.sol";
import {Survey} from "../src/Survey.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
forge script script/DeployContracts.s.sol \
    --rpc-url http://127.0.0.1:8545 \
    --broadcast

forge script script/DeployContracts.s.sol \
    --rpc-url $RPC_URL_SEPOLIA \
    --optimizer-runs 200 \
    --broadcast \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --private-key=$PRIVATE_KEY \
    --tc DeployContracts

forge verify-contract \
    --chain-id 11155111 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --optimizer-runs 200 \
    0x940fafd7cB44d56Ab491CF36BE8BC66027Ac8273 \
    src/Staking.sol:Staking

    forge verify-contract \
    --chain-id 11155111 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --optimizer-runs 200 \
    0xBFd74146432be29b779D5bc59322AcFba1e241c2 \
    src/Survey.sol:Survey
 */
abstract contract DeployScript is Script {
    address public stakingProxy;
    address public stakingImpl;
    bytes public stakingData;

    address public surveyProxy;
    address public surveyImpl;
    bytes public surveyData;

    address deployerAddress;
    address upgraderAddress;
    address adminAddress;

    error InvalidAddress(string reason);

    modifier create() {
        _;
        if (stakingImpl == address(0)) {
            revert InvalidAddress("stakingImpl address can not be zero");
        }
        stakingProxy = address(new ERC1967Proxy(stakingImpl, stakingData));

        if (surveyImpl == address(0)) {
            revert InvalidAddress("surveyImpl address can not be zero");
        }
        surveyProxy = address(new ERC1967Proxy(surveyImpl, surveyData));
    }

    // modifier upgrade() {
    //     _;
    //     if (stakingProxy == address(0)) {
    //         revert InvalidAddress("proxy address can not be zero");
    //     }
    //     if (stakingImpl == address(0)) {
    //         revert InvalidAddress("stakingImpl address can not be zero");
    //     }
    //     UUPSUpgradeable proxy = UUPSUpgradeable(stakingProxy);
    //     proxy.upgradeToAndCall(address(stakingImpl), stakingData);
    // }

    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 deployerKey, address deployer, address admin, address upgrader) =
            helperConfig.config();
        deployerAddress = deployer;
        upgraderAddress = upgrader;
        adminAddress = admin;

        vm.startBroadcast(deployerKey);
        _run();
        vm.stopBroadcast();
    }

    function _run() internal virtual;
}

contract DeployContracts is DeployScript {
    constructor() DeployScript() {}

    //slither-disable-next-line reentrancy-no-eth
    function _run() internal override create {
        Staking staking = new Staking();
        stakingImpl = address(staking);
        stakingData = abi.encodeCall(staking.initialize, (deployerAddress, upgraderAddress));

        Survey survey = new Survey();
        surveyImpl = address(survey);
        surveyData = abi.encodeCall(survey.initialize, (deployerAddress,upgraderAddress,adminAddress,stakingProxy));
    }
}

// contract DeployContractsV2 is DeployScript {
//     constructor() DeployScript(vm.envUint("PRIVATE_KEY")) {
//         stakingProxy = vm.envAddress("PROXY");
//     }

//     //slither-disable-next-line reentrancy-no-eth
//     function _run() internal override upgrade {
//         StakingV2 c = new StakingV2();
//         stakingImpl = address(c);
//         stakingData = bytes.concat(c.upgradeVersion.selector);
//     }
// }
