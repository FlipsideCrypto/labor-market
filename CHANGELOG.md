---
tag: docs
---

# Changelog

All notable changes to this project will be documented in this file.

The key for the types of changes are as follows:

-   ✨ New
-   👷 Change
-   🐛 Bug
-   🩸 Removal
-   🔮 Future Proofing

-   CINAD (sigh-nad): Chain Is Not A Database

## [2.0.2] - 2023-05-05

-   ✨ Added Requester controlled ability to set the maximum signal intent at which they can cancel.
-   ✨ Colateral can optionally be configured to provide financialized obligation for signaled intent.

## [2.0.1] - 2023-05-04

-   ✨ Added `maxSubmissions` to `Request` experienced explicitly by providers through `signal`.
-   ✨ Added `maxReviews` to `Request` experienced explicitly by reviewers through `review`.
-   ✨ Added N-Badge Authority mechanism to allow for complex & configurable gating mechanisms.
-   ✨ ERC-20 ($pToken) distribution (optional) to Reviewers upon successful review.

## [2.0.0] - 2023-05-03

v2.0.0 is the first major release of the Labor Market protocol. This release is a culmination of the lessons learned
from the v1.x.x releases and the feedback from the community. This release is a breaking change from the previous
versions and is not backwards compatible.

The primary focus of this release is to improve the experience of the Requester and Provider while establishing a
framework that enables ephemeral and long-term labor markets to co-exist.

-   ✨ Added `uri` as a `calldata` parameter for event emission use only.
-   ✨ Use of `SignalCount` struct using two `uint128`s to track activity in a request.
-   ✨ Total number of submissions signalled to be reviewed by an address cannot exceed 4,194,304 (2^22).
-   ✨ Store the addresses that have a valid Request submission in an `EnumerableSet.AddressSet` for inline slot access.
-   ✨ Updated `submissionId` to be defined as `uint256(uint160(msg.sender))` due to the 1 submission per address limit.
    -   📝 This will always result in a unique id relative to the provider.
-   ✨ Distribution of funds may "fail" without being blocking due to the `if` check on `amount > 0`.
-   ✨ The returned response when distributing funds is carried with a boolean of success.
-   ✨ CINAD: When a submission has the associated earnings claimed, delete the submission from storage.
-   ✨🔮 Can now distribute the finalized funds sitting in the protocol on behalf of and to the respective participant.
-   👷🔮 Only when the `Enforcement Criteria` returns `newSubmission` as `true` is review signal intent deducted.
-   👷🔮 A customized `Enforcement Criteria` may return a non-standard `intentChange` enabling for more complex logic.
-   👷 Response of claim functions have been updated to `(bool success, uint256 amount)` for inline static calls.
-   👷 Labor Market factory no longer enforces review uniqueness allowing for multi-stage and editing of reviews.
-   👷 Use `public virtual` functions rather than `external`.
-   👷 Improved the signature definition of all key events.
-   👷 Base the generation of `requestId` upon an `(encoded(block.timestamp, msg.sender))` for all Requests
-   👷 Use of `ServiceRequest` struct in `setRequest` rather than a bunch of parameters.
-   👷 CINAD: Improved the onchain implementation of signal tracking to be more gas efficient.
-   🐛 Fixed bug where `strings` where marked as `indexed` in events. (🏆 @Not Playwololo)
-   🐛 Fixed bug where struct storage was not implemented as intended.
-   🩸 $rMETRIC and all supporting functionality such as decay, manager access, etc. has been deprecated.
-   🩸 Removed the staking of ERC-1155 upon signalling as Provider and Reviewer.
-   🩸 All native implementations and functionality of reputation ($rMETRIC) have been deprecated.
    -   📝 Badges are not revoked upon signalling as social access != financial collateral.
-   🩸 CINAD: Removed globally incremented `serviceId`.
-   🩸 CINAD: Removed the need to manually track `serviceCount`.
-   🩸 CINAD: Removed the logic mechanism making the `requestId` incremental.
-   🩸 CINAD: Removed `uri` from `ServiceRequest` struct.
-   🩸 CINAD: Removed entire architecture of `hasPerformed` due to it being a triple nested mapping.
-   🩸 CINAD: Removed all uses and storage of the `ServiceSubmission` struct.
-   🩸 CINAD: Removed need to signal before participation when signal threshold is zero.
-   🩸 CINAD: Removed limitation of 're-signaling' that was based upon `reminder == 0`.
-   🩸 CINAD: Removed inclusion of `reviewStake` in `ReviewSignal` event.
-   🩸🔮 Removed requirement to be the caller of the participant one is distributing the funds of.
-   🩸🔮 Removed ability to define `_to` when claiming payment earned by a Provider.
-   🩸🔮 Removed single-pass limit from `claimRemainder` to enable claiming as long as funds exist after enforcement.
-   🩸🔮 Deprecated the use of `retrieveReputation` as it is no longer needed.

## [1.6.0] - 2022-07-17

v1.6.0 is the first round of feedback implementation that addresses several of the key issues experienced during
protocol integration with a frontend system supported by an application layer and team. To maintain the best experience
possible for all consumers of the protocol, this update had one focus: make the protocol easier to integrate with.

Without more information of model consumption, this update was solely developed for the Operators of the Labor Market.
Future updates will address the nuance and experience of Providers and Requesters more directly.

-   ✨ Added [NPM package](https://www.npmjs.com/package/labor-markets-abi) to assist with protocol consumption pains.
-   ✨ Added ability for Scalable Likert can serve as Constant Likert when the Buckets are unset or given weights of 1
-   ✨ Added ability for Requesters to claim the funding surplus if no qualified submissions exist after enforcement.
-   ✨ Added ability to make request creation public by setting the Delegate badge to the zero address.
-   ✨ Added [[Labor Market#getRewards|getRewards]]
-   ✨ Added [[Network#isGovernor|isGovernor]], [[Labor Market#isMaintainer|isMaintainer]],
    [[Network#isCreator|isCreator]], and [[Labor Market#isPermittedParticipant|isPermittedParticipant]] as read calls to
    determine permissions.
-   ✨ Added NatSpec documentation to contract functions and values.
-   👷 Improved math for determining payouts and score resulting in a ~400% increase in precision.
    -   📝 The small amount of dust left over from rounding with solidity math averages out to ~`0.00000000000000002`
        using the standard 18 decimals.
    -   📝 Since Constant and Scalable Likert does not often have remainders, it instead catches when all submissions
        earned 0 either through too low of scores or no reviews came in.
-   👷 Improved `signalStake()` in [[Labor Market#ReputationParams|ReputationParams]], with 'provideStake' and
    'reviewStake' to be more intuitive and verbose.
-   ✨ Added a bytes32 enforcement key to point to a specific bucket configuration.
    -   📝 This key is not intended for v2 but until we start optimizations this is how it will be handled.
    -   📝 [[Labor Market#LaborMarketConfiguration|LaborMarketConfiguration]] - [[Labor Market#Modules|Modules]]
-   🐛 Fixed a actions-time bug by requiring that each phase of a request is sequential and in the future.
-   🩸 Removed payment module address.
-   🩸 Removed unused functions, variables and dependencies to minimize bytecode.
-   🩸 CINAD: Removed the logic storing submissions scores onchain in an array.

(Previous versions were not documented due to the significant architecture shifts that took place.)
