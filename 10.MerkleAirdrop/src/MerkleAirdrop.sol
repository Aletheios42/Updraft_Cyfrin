// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title MerkleAirdrop
 * @author Aletheios42
 *
 */

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    /**************************************************************************/
    /*                                 Errors                                 */
    /**************************************************************************/

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop_InvalidSignature();
    error MerkleAirdrop_AlreadyClaimed();

    /**************************************************************************/
    /*                                 Events                                 */
    /**************************************************************************/
    event Claim(address account, uint256 amount);

    /**************************************************************************/
    /*                            State Variables                             */
    /**************************************************************************/

    address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimers => bool claimed) private s_hasClaimed;
    bytes32 private constant MESSAGE_TYPEDHASH =
        keccak256("AirdropClaim(address account, uint256 amount)");
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop_AlreadyClaimed();
        }
        if (
            !isValidSignature(account, getMessageHash(account, amount), v, r, s)
        ) {
            revert MerkleAirdrop_InvalidSignature();
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMessageHash(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MESSAGE_TYPEDHASH,
                        AirdropClaim({account: account, amount: amount})
                    )
                )
            );
    }

    function isValidSignature(
        address account,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
