// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { ReputationModuleInterface } from "./interfaces/ReputationModuleInterface.sol";
import { BadgerOrganizationInterface } from "../Badger/interfaces/BadgerOrganizationInterface.sol";

/// @dev Helper interfaces.
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract ReputationModule is 
    ReputationModuleInterface,
    ContextUpgradeable
{
    /// @dev The Labor Market Network permissioned to make actions.
    address public network;

    /// @dev The configuration for a given Labor Market.
    mapping(address => MarketReputationConfig) public marketRepConfig;

    /// @dev The decay configuration of a given reputation token.
    mapping(address => mapping(uint256 => DecayConfig)) public decayConfig;

    /// @dev The decay and freezing state for an account for a given reputation token.
    mapping(address => mapping(uint256 => mapping(address => ReputationAccountInfo))) public accountInfo;

    /// @dev When the reputation implementation of a market is changed.
    event MarketReputationConfigured (
          address indexed market
        , address indexed reputationToken
        , uint256 indexed reputationTokenId
    );

    /// @dev When the decay configuration of a reputation token is changed.
    event ReputationDecayConfigured (
          address indexed reputationToken
        , uint256 indexed reputationTokenId
        , uint256 decayRate
        , uint256 decayInterval
        , uint256 decayStartEpoch
    );

    /// @dev When the balance of an account is changed.
    event ReputationBalanceChange (
        address indexed account,
        address indexed reputationToken,
        uint256 indexed reputationTokenId,
        int256 amount
    );

    constructor(
        address _network
    ) {
        network = _network;
    }

    /**
     * @notice Initialize a new Labor Market as using Reputation.
     * @param _laborMarket The address of the new Labor Market.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * Requirements:
     * - Only the network can call this function when creating a new market.
     */
    function useReputationModule(
          address _laborMarket
        , address _reputationToken
        , uint256 _reputationTokenId
    )
        override
        external
    {
        /// @dev Only the network can call this function when configuring a market.
        require(
            _msgSender() == network, 
            "ReputationModule: Only network can call this."
        );

        /// @dev Configure the market to use the given reputation token.
        marketRepConfig[_laborMarket] = MarketReputationConfig({
              reputationToken: _reputationToken
            , reputationTokenId: _reputationTokenId
        });

        emit MarketReputationConfigured(
              _laborMarket
            , _reputationToken
            , _reputationTokenId
        );
    }

     /**
     * @notice Utilize and burn reputation.
     * @param _account The account to burn reputation from.
     * @param _amount The amount of reputation to burn.
     */
    function useReputation(
          address _account
        , uint256 _amount
    )
        external
        override
    {
        /// @dev Revokes reputation from the account.
        _revokeReputation(
            marketRepConfig[_msgSender()].reputationToken,
            marketRepConfig[_msgSender()].reputationTokenId,
            _account,
            _amount
        );
    }

    /**
     * @notice Lock and freeze reputation for an account, avoiding decay.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * @param _frozenUntilEpoch The epoch until which the reputation is frozen.
     *
     * Requirements:
     * - The frozenUntilEpoch must be in the future.
     */
    function freezeReputation(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    )
        external
        override
    {   
        /// @dev The frozenUntilEpoch must be in the future.
        require(
            _frozenUntilEpoch > block.timestamp,
            "ReputationModule: Cannot retroactively freeze reputation."
        );

        /// @dev Apply pending decay to the account.
        _revokeReputation(
            _reputationToken,
            _reputationTokenId,
            _msgSender(),
            0
        );

        /// @dev Freeze the account's reputation.
        accountInfo[_reputationToken][_reputationTokenId][_msgSender()].frozenUntilEpoch = _frozenUntilEpoch;
    }

    /**
     * @notice Mint reputation for a given account.
     * @param _account The account to mint reputation for.
     * @param _amount The amount of reputation to mint.
     * Requirements:
     * - The sender must be a Labor Market.
     * - The Labor Market must have been initialized with the Reputation Module.
     */
    function mintReputation(
          address _account
        , uint256 _amount
    )
        external
        override
    {
        MarketReputationConfig memory config = marketRepConfig[_msgSender()];

        /// @dev Market must be initialized with the Reputation Module.
        require(
            config.reputationToken != address(0), 
            "ReputationModule: This Labor Market has not been initialized."
        );

        /// @dev Mint the reputation.
        BadgerOrganizationInterface(config.reputationToken).leaderMint(
            _account,
            config.reputationTokenId,
            _amount,
            ""
        );

        /// @dev Emit the event.
        emit ReputationBalanceChange(
            _account,
            config.reputationToken,
            config.reputationTokenId,
            int256(_amount)
        );
    }

    /**
     * @notice Set the decay configuration for a reputation token.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * @param _decayRate The rate of decay.
     * @param _decayInterval The interval of decay.
     * @param _decayStartEpoch The epoch at which decay starts.
     * Requirements:
     * - Only the network can call this function.
     * - The network function caller must be a Governor.
     */
    function setDecayConfig(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external
        override
    {
        /// @dev Require the caller to be the network.
        require(_msgSender() == network, "ReputationModule: Only network can call this.");

        /// @dev Set the decay configuration.
        decayConfig[_reputationToken][_reputationTokenId] = DecayConfig({
              decayRate: _decayRate
            , decayInterval: _decayInterval
            , decayStartEpoch: _decayStartEpoch
        });

        /// @dev Emit the event.
        emit ReputationDecayConfigured(
            _reputationToken
            , _reputationTokenId
            , _decayRate
            , _decayInterval
            , _decayStartEpoch
        );
    }

    /**
     * @notice Get the amount of reputation that is available to use.
     * @dev This function takes into account non-applied decay and the frozen state.
     * @param _laborMarket The Labor Market context.
     * @param _account The account to check.
     * @return _availableReputation The amount of reputation that is available to use.
     */
    function getAvailableReputation(
        address _laborMarket,
        address _account
    )
        external
        view
        override
        returns (
            uint256 _availableReputation
        )
    {
        /// @dev Get the market's reputation parameters.
        MarketReputationConfig memory config = marketRepConfig[_laborMarket];
        ReputationAccountInfo memory info = accountInfo[config.reputationToken][config.reputationTokenId][_account];

        /// @dev If the account's reputation is frozen, return 0.
        if (info.frozenUntilEpoch > block.timestamp) return 0;

        /// @dev Get the amount of reputation that has decayed.
        uint256 decayed = _getReputationDecay(
            config.reputationToken,
            config.reputationTokenId,
            info.frozenUntilEpoch,
            info.lastDecayEpoch
        );

        /// @dev Get the amount of reputation that is available.
        _availableReputation = IERC1155(config.reputationToken).balanceOf(
            _account,
            config.reputationTokenId
        );

        /// @dev Return the available reputation, or 0 if it is less than the decayed amount.
        return _availableReputation > decayed ? _availableReputation - decayed : 0;
    }

    /**
     * @notice Get the amount of reputation that is pending decay.
     * @param _laborMarket The Labor Market context.
     * @param _account The account to check.
     * @return The amount of reputation that is pending decay.
     */
    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        override
        returns (
            uint256
        )
    {
        MarketReputationConfig memory config = marketRepConfig[_laborMarket];

        return _getReputationDecay(
            config.reputationToken,
            config.reputationTokenId,
            accountInfo[config.reputationToken][config.reputationTokenId][_account].frozenUntilEpoch,
            accountInfo[config.reputationToken][config.reputationTokenId][_account].lastDecayEpoch
        );
    }

    /**
     * @notice Manage the revoking of reputation and the decay application.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * @param _account The account to revoke reputation from.
     * @param _amount The amount of reputation to revoke.
     */
    function _revokeReputation(
          address _reputationToken
        , uint256 _reputationTokenId
        , address _account
        , uint256 _amount
    )
        internal
    {
        /// @dev Get the balance of the account.
        uint256 balance = IERC1155(_reputationToken).balanceOf(
            _account,
            _reputationTokenId
        );

        /// @dev Require the account to have enough reputation to use.
        require(
            balance >= _amount,
            "ReputationModule: Not enough reputation to use."
        );

        /// @dev Load the account info.
        ReputationAccountInfo storage info = accountInfo[_reputationToken][_reputationTokenId][_account];

        /// @dev Get the amount of reputation that has decayed.
        uint256 decay = _getReputationDecay(
            _reputationToken, 
            _reputationTokenId,
            info.frozenUntilEpoch,
            info.lastDecayEpoch
        );

        /// @dev If decay is more than the balance, use balance.
        _amount += decay;
        if (_amount > balance) 
            _amount = balance;

        /// @dev Set the last decay epoch.
        info.lastDecayEpoch = block.timestamp;

        /// @dev Revoke the reputation.
        BadgerOrganizationInterface(_reputationToken).revoke(
            _account,
            _reputationTokenId,
            _amount
        );

        emit ReputationBalanceChange(
            _account,
            _reputationToken,
            _reputationTokenId,
            int256(_amount) * -1
        );
    }

    /**
     * @notice Get the amount of reputation that has decayed.
     * @param _reputationToken The reputation token to check.
     * @param _reputationTokenId The reputation token ID to check.
     * @param _frozenUntilEpoch The epoch that the reputation is frozen until.
     * @param _lastDecayEpoch The epoch that the reputation was last decayed.
     * @return The amount of reputation that has decayed.
     */
    function _getReputationDecay(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
        , uint256 _lastDecayEpoch
    )
        internal
        view
        returns (
            uint256
        )
    {
        DecayConfig memory decay = decayConfig[_reputationToken][_reputationTokenId];

        /// @dev Get the most recent epoch to start decay from.
        uint256 startEpoch = decay.decayStartEpoch;

        if (_frozenUntilEpoch > startEpoch) 
            startEpoch = decay.decayStartEpoch;
        if (_lastDecayEpoch > startEpoch) 
            startEpoch = _lastDecayEpoch;
        
        /// @dev If the start epoch is in the future, the decay rate is 0, or decay hasn't started, return 0.
        if (
            startEpoch > block.timestamp ||
            decay.decayStartEpoch == 0 ||
            decay.decayRate == 0
        ) {
            return 0;
        }

        /// @dev Return the amount of decay.
        return (block.timestamp - startEpoch) /
            decay.decayInterval * decay.decayRate;
    }
}