// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {UPPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UPPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BoxV1 is Initializable, UPPSUpgradeable, OwnableUpgradeable {
    uint256 internal number;

    ///@custom_oz-upgrades-unsafe-allow contructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(); //calls tranferOwnnership with msg.sender
        __UUPSUpgradeable_init();
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
