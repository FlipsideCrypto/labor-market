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

    /// @dev The decay configuration of a given reputation token.
    mapping(address => mapping(uint256 => DecayConfig)) public decayConfig;

    /// @dev The configuration for a given Labor Market.
    mapping(address => MarketReputationConfig) public marketRepConfig;

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
        require(
            _msgSender() == network, 
            "ReputationModule: Only network can call this."
        );

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
        _revokeReputation(
            marketRepConfig[_msgSender()].reputationToken,
            marketRepConfig[_msgSender()].reputationTokenId,
            _account,
            _amount
        );
    }

    /**
     * @notice Lock and freeze reputation for an account, avoiding decay.
     * @param _account The account to freeze reputation for.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * @param _frozenUntilEpoch The epoch until which the reputation is frozen.
     * Requirements:
     * - The frozenUntilEpoch must be in the future.
     */
    function freezeReputation(
          address _account
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    )
        external
        override
    {   
        require(
            _frozenUntilEpoch > block.timestamp,
            "ReputationModule: Cannot retroactively freeze reputation."
        );

        _revokeReputation(
            _reputationToken,
            _reputationTokenId,
            _account,
            0
        );

        accountInfo[_reputationToken][_reputationTokenId][_account].frozenUntilEpoch = _frozenUntilEpoch;
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

        require(
            config.reputationToken != address(0), 
            "ReputationModule: This Labor Market has not been initialized."
        );

        BadgerOrganizationInterface(config.reputationToken).leaderMint(
            _account,
            config.reputationTokenId,
            _amount,
            ""
        );

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
        require(_msgSender() == network, "ReputationModule: Only network can call this.");

        decayConfig[_reputationToken][_reputationTokenId] = DecayConfig({
              decayRate: _decayRate
            , decayInterval: _decayInterval
            , decayStartEpoch: _decayStartEpoch
        });

        emit ReputationDecayConfigured(
            _reputationToken
            , _reputationTokenId
            , _decayRate
            , _decayInterval
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
        MarketReputationConfig memory config = marketRepConfig[_laborMarket];
        ReputationAccountInfo memory info = accountInfo[config.reputationToken][config.reputationTokenId][_account];

        if (info.frozenUntilEpoch > block.timestamp) return 0;

        uint256 decayed = _getReputationDecay(
            config.reputationToken,
            config.reputationTokenId,
            info.frozenUntilEpoch,
            info.lastDecayEpoch
        );

        _availableReputation = IERC1155(config.reputationToken).balanceOf(
            _account,
            config.reputationTokenId
        );

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
     * @notice Get the ERC1155 token address and ID for a given Labor Market.
     * @param _laborMarket The Labor Market to check.
     * @return The ERC1155 token address and ID for a given Labor Market.
     */
    function getMarketReputationConfig(
        address _laborMarket
    )
        external
        view
        override
        returns (
            MarketReputationConfig memory
        )
    {
        return marketRepConfig[_laborMarket];
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
        uint256 balance = IERC1155(_reputationToken).balanceOf(
            _account,
            _reputationTokenId
        );

        require(
            balance >= _amount,
            "ReputationModule: Not enough reputation to use."
        );

        ReputationAccountInfo storage info = accountInfo[_reputationToken][_reputationTokenId][_account];

        uint256 decay = _getReputationDecay(
            _reputationToken, 
            _reputationTokenId,
            info.frozenUntilEpoch,
            info.lastDecayEpoch
        );

        // If decay is more than the balance, just take all balance.
        uint256 amount = _amount + decay;
        if (amount > balance) amount = balance;

        info.lastDecayEpoch = block.timestamp;

        BadgerOrganizationInterface(_reputationToken).revoke(
            _account,
            _reputationTokenId,
            amount
        );

        emit ReputationBalanceChange(
            _account,
            _reputationToken,
            _reputationTokenId,
            int256(amount) * -1
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

        if (
            _frozenUntilEpoch > block.timestamp || 
            decay.decayRate == 0
        ) {
            return 0;
        }

        // If the last decay epoch is greater than the decay start epoch, use that.
        uint256 startEpoch = _lastDecayEpoch > decay.decayStartEpoch ? 
            _lastDecayEpoch : decay.decayStartEpoch;

        return (((block.timestamp - startEpoch - _frozenUntilEpoch) /
            decay.decayInterval) * decay.decayRate);
    }
}