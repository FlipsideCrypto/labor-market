// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ReputationEngineInterface } from "./interfaces/ReputationEngineInterface.sol";

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// TODO: Add the Badger functions for minting and revoking.
// TODO: Should we apply decay on freeze and on unlock? Just on freeze? The getAvailableReputation
//       function accounts for the decay for external checks.
// TODO: Should decayed reputation emit its own event?

contract ReputationEngine is 
      ReputationEngineInterface
    , OwnableUpgradeable
{
    address public module;

    IERC1155 public baseToken;
    uint256 public baseTokenId;

    uint256 public decayRate;
    uint256 public decayInterval;

    mapping(address => ReputationAccountInfo) public accountInfo;

    event ReputationFrozen (
        address indexed account,
        uint256 frozenUntilEpoch
    );

    event ReputationLocked (
        address indexed account,
        uint256 amount
    );

    event ReputationUnlocked (
        address indexed account,
        uint256 amount
    );

    event ReputationDecayed (
        address indexed account,
        uint256 amount
    );

    event ReputationDecayConfigured (
        uint256 decayRate,
        uint256 decayInterval
    );

    modifier onlyModule() {
        require(msg.sender == module, "ReputationToken: Only the module can call this function.");
        _;
    }

    function initialize(
          address _module
        , address _baseToken
        , uint256 _baseTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
    ) 
        external
        override
        initializer
    {
        module = _module;
        baseToken = IERC1155(_baseToken);
        baseTokenId = _baseTokenId;
        decayRate = _decayRate;
        decayInterval = _decayInterval;
    }

    /**
     * @notice Change the decay parameters of the reputation token.
     * @param _decayRate The amount of reputation decay per epoch.
     * @param _decayInterval The block length of an epoch.
     * Requirements:
     * - Only the owner can call this function.
     */
    function setDecayConfig(
          uint256 _decayRate
        , uint256 _decayInterval
    ) 
        override
        external 
        onlyOwner 
    {
        decayRate = _decayRate;
        decayInterval = _decayInterval;

        emit ReputationDecayConfigured(_decayRate, _decayInterval);
    }

    /**
     * @notice Freeze a user's reputation for a given number of epochs.
     * @param _frozenUntilEpoch The epoch that reputation will no longer be frozen.
     * @dev Calculates decay and applies it before freezing.
     *
     * Requirements:
     * - `_frozenUntilEpoch` must be greater than the current epoch.
     */
    function freezeReputation(
          address _account
        , uint256 _frozenUntilEpoch
    )
        override
        external
        onlyModule
    {
        ReputationAccountInfo storage info = accountInfo[_account];
        uint256 decay = getPendingDecay(_account);

        info.frozenUntilEpoch = _frozenUntilEpoch;
        info.locked += decay;
        info.lastDecayEpoch = block.timestamp;

        emit ReputationDecayed(_account, decay);
        emit ReputationFrozen(_account, _frozenUntilEpoch);
    }

    /**
     * @notice Lock reputation for a given account.
     * @param _account The address to lock reputation for.
     * @param _amount The amount of reputation to lock.
     */
    function lockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        external 
        onlyModule
    {
        uint256 decay = getPendingDecay(_account);

        accountInfo[_account].locked += _amount + decay;

        emit ReputationDecayed(_account, decay);
        emit ReputationLocked(_account, _amount);
    }

    /**
     * @notice Reduce the amount of locked reputation for a given account.
     * @param _account The address to retreive decay of.
     * @param _amount The amount of reputation to unlock.
     */
    function unlockReputation(
          address _account
        , uint256 _amount
    ) 
        override
        external 
        onlyModule
    {
        uint256 decay = getPendingDecay(_account);

        accountInfo[_account].locked -= _amount + decay;

        emit ReputationDecayed(_account, decay);
        emit ReputationUnlocked(_account, _amount);
    }

    /**
     * @notice Returns the available reputation token balance after accounting for the
     *         amounts locked and pending decay.
     * @param _account The address to query the balance of.
     * Requirements:
     * - If a user's balance is frozen, no reputation is available.
     */
    function getAvailableReputation(address _account)
        override
        external
        view
        returns (
            uint256
        )
    {
        ReputationAccountInfo memory info = accountInfo[_account];

        if (info.frozenUntilEpoch > block.timestamp) return 0;

        uint256 decayed = getPendingDecay(_account);

        return (
            baseToken.balanceOf(
                _account,
                baseTokenId
            ) - info.locked - decayed
        );
    }

    /**
     * @notice Get the amount of reputation of an account that has decayed since 
     *         the last decay epoch.
     * @param _account The address to retreive decay of.
     * @dev This function assumes that anywhere decay is written to storage, the
     *      account's frozenUntilEpoch is set to 0.
     */
    function getPendingDecay(address _account)
        override
        public
        view
        returns (
            uint256
        )
    {
        ReputationAccountInfo memory info = accountInfo[_account];

        if (info.frozenUntilEpoch > block.timestamp || decayRate == 0) {
            return 0;
        }

        return (((block.timestamp - info.lastDecayEpoch - info.frozenUntilEpoch) /
            decayInterval) * decayRate);
    }

    /**
     * @notice Get the reputation info of an account.
     * @param _account The address to retreive reputation info of.
     */
    function getReputationAccountInfo(address _account)
        override
        external
        view
        returns (
            ReputationAccountInfo memory
        )
    {
        return accountInfo[_account];
    }
}