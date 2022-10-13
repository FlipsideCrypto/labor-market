// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LaborMarketFactory} from "./LaborMarketFactory.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LaborMarketNetwork is LaborMarketFactory {
    IERC1155 public reputationToken;
    IERC20 public capacityToken;

    uint256 public reputationTokenId;
    uint256 public reputationDecayRate;
    uint256 public reputationDecayInterval;

    uint256 public baseSignalStake;
    uint256 public baseProviderThreshold;
    uint256 public baseMaintainerThreshold;

    // TODO: Packing?
    struct BalanceInfo {
        uint256 locked;
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    mapping(address => BalanceInfo) private _balanceInfo;

    constructor(
        address _factoryImplementation,
        address _reputationImplementation,
        address _capacityImplementation,
        uint256 _baseSignalStake,
        uint256 _baseProviderThreshold,
        uint256 _baseMaintainerThreshold,
        uint256 _reputationTokenId,
        uint256 _reputationDecayRate,
        uint256 _reputationDecayInterval
    ) LaborMarketFactory(_factoryImplementation) {
        baseSignalStake = _baseSignalStake;
        baseProviderThreshold = _baseProviderThreshold;
        baseMaintainerThreshold = _baseMaintainerThreshold;

        reputationToken = IERC1155(_reputationImplementation);
        reputationTokenId = _reputationTokenId;
        reputationDecayRate = _reputationDecayRate;
        reputationDecayInterval = _reputationDecayInterval;

        capacityToken = IERC20(_capacityImplementation);
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    function setReputationImplementation(address _reputationImplementation)
        external
        onlyOwner
    {
        reputationToken = IERC1155(_reputationImplementation);
    }

    function setCapacityImplementation(address _capacityImplementation)
        external
        onlyOwner
    {
        capacityToken = IERC20(_capacityImplementation);
    }

    function setReputationTokenId(uint256 _reputationTokenId)
        external
        onlyOwner
    {
        reputationTokenId = _reputationTokenId;
    }

    function setBaseSignalStake(uint256 _amount) external onlyOwner {
        baseSignalStake = _amount;
    }

    function setBaseProviderThreshold(uint256 _amount) external onlyOwner {
        baseProviderThreshold = _amount;
    }

    function setBaseMaintainerThreshold(uint256 _amount) external onlyOwner {
        baseMaintainerThreshold = _amount;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the available reputation token balance after accounting for the
     *         amounts locked and pending decay.
     * @param _account The address to query the balance of.
     * Requirements:
     * - If a user's balance is frozen, no reputation is available.
     */
    function getAvailableReputation(address _account)
        public
        view
        returns (uint256)
    {
        BalanceInfo memory info = _balanceInfo[_account];

        if (info.frozenUntilEpoch > block.timestamp) return 0;

        uint256 decayed = _getPendingDecay(
            info.lastDecayEpoch,
            info.frozenUntilEpoch
        );

        return (reputationToken.balanceOf(_account, reputationTokenId) -
            info.locked -
            decayed);
    }

    /**
     * @notice Freeze a user's reputation for a given number of epochs.
     * @param _frozenUntilEpoch The epoch that reputation will no longer be frozen.
     * @dev Calculates decay and applies it before freezing.
     *
     * Requirements:
     * - `_frozenUntilEpoch` must be greater than the current epoch.
     */
    function freezeReputation(uint256 _frozenUntilEpoch) external {
        require(
            block.timestamp > _frozenUntilEpoch,
            "Network: Cannot freeze reputation in the past"
        );

        BalanceInfo storage info = _balanceInfo[_msgSender()];
        uint256 decayed = _getPendingDecay(
            info.lastDecayEpoch,
            info.frozenUntilEpoch
        );

        info.locked += decayed;
        info.frozenUntilEpoch = _frozenUntilEpoch;
        info.lastDecayEpoch = block.timestamp;
    }

    /**
     * @notice Get the amount of reputation that has decayed since the last decay epoch.
     * @param _lastDecayEpoch The epoch that reputation was last decayed.
     * @param _frozenUntilEpoch The epoch that reputation will no longer be frozen.
     * @dev This function assumes that anywhere decay is written to storage, the
     *      user's frozenUntilEpoch is set to 0.
     */
    function _getPendingDecay(
        uint256 _lastDecayEpoch,
        uint256 _frozenUntilEpoch
    ) internal view returns (uint256) {
        if (_frozenUntilEpoch > block.timestamp) {
            return 0;
        }

        return (((block.timestamp - _lastDecayEpoch - _frozenUntilEpoch) /
            reputationDecayInterval) * reputationDecayRate);
    }

    // Todo: Access controls
    function lockReputation(address user, uint256 amount) external {
        _balanceInfo[user].locked += amount;
    }
}
