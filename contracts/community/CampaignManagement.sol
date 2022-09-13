// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../consensus/AdminConsensus.sol";
import "./ICampaignManagement.sol";

/**
 *@author tuan.dq
 *@title Smart contract for campaigns
 */

contract CampaignManagement is
  ICampaignManagement,
  AdminConsensus,
  ReentrancyGuard
{
  /**
   *@dev Using safe math library for uin256
   */
  using SafeMath for uint256;

  /**
   *@dev Using safe math library for uin256
   */
  using SafeERC20 for IERC20;

  /**
   *  @dev ERC20 token for this smart contract
   */
  IERC20 public _token;

  /**
   *  @dev array save all campaign name.
   */
  string[] private _campaignNames;

  /**
   *@dev data by times
   */
  DataByTime[] private _datas;

  /**
   *  @dev Mapping from campaign to participants.
   */
  mapping(string => Campaign) private _campaigns;

  /**
   *  @dev Mapping from campaign to participants.
   */
  mapping(string => mapping(address => AdminConsentStatus))
    public campaignConsents;

  Set private _participants;

  modifier enoughReleaseConsensus(string memory campaignName) {
    uint256 totalCampaignConsensus = _getConsensusByNameAndStatus(
      campaignName,
      AdminConsentStatus.Accept
    );
    uint256 adminsLength = _admins.length;
    require(
      totalCampaignConsensus > adminsLength.div(2),
      "Not enough consensus!"
    );
    _;
  }

  modifier enoughDeleteConsensus(string memory campaignName) {
    uint256 totalCampaignConsensus = _getConsensusByNameAndStatus(
      campaignName,
      AdminConsentStatus.Reject
    );
    uint256 adminsLength = _admins.length;
    require(
      totalCampaignConsensus > adminsLength.div(2),
      "Not enough consensus!"
    );
    _;
  }

  modifier confirmedRelease(string memory campaignName) {
    require(
      (campaignConsents[campaignName][msg.sender] != AdminConsentStatus.Reject),
      "Account not already confirmed release!"
    );
    _;
  }
  modifier notConfirmedRelease(string memory campaignName) {
    require(
      (campaignConsents[campaignName][msg.sender] != AdminConsentStatus.Accept),
      "Account already confirmed release!"
    );
    _;
  }

  modifier isExist(string memory campaignName) {
    require(
      (_campaigns[campaignName].participants.length == 0),
      "Unable to create a new campaign that already exists!"
    );
    _;
  }

  /**
   *  @dev Set address token. Deployer is a admin.
   */
  constructor(
    IERC20 token_,
    uint256[] memory times_,
    uint256[] memory amounts_
  ) {
    _token = token_;
    uint256 fractions = 10**uint256(18);
    _validateTimesAndAmounts(times_, amounts_);
    for (uint256 i = 0; i < amounts_.length; i++) {
      _datas.push(DataByTime(times_[i], amounts_[i] * fractions));
    }
  }

  /**
   *@dev Create campaign
   */
  function createCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 releaseTime
  ) public override onlyAdmin nonReentrant isExist(campaignName) {
    _createCampaign(campaignName, accounts, amounts, releaseTime, false);
  }

  /**
   *  @dev  Admin accept for campaign release token.
   */
  function adminAcceptRelease(string memory campaign)
    public
    override
    onlyAdmin
    notConfirmedRelease(campaign)
  {
    _adminAcceptRelease(campaign);
  }

  /**
   *  @dev  Admin reject for campaign release token.
   */
  function adminRejectRelease(string memory campaign)
    public
    override
    onlyAdmin
    confirmedRelease(campaign)
  {
    _adminRejectRelease(campaign);
  }

  /**
   *@dev Create campaign
   */
  function release(string memory campaignName, bool passive)
    public
    override
    onlyAdmin
    enoughReleaseConsensus(campaignName)
  {
    require(
      block.timestamp >= _campaigns[campaignName].releaseTime,
      "It's not time yet!"
    );

    require(
      (_campaigns[campaignName].status == CampaignStatus.NoAction),
      "Campaign ended!"
    );

    Participant[] memory listParticipant = _campaigns[campaignName]
      .participants;
    for (uint256 i = 0; i < listParticipant.length; i++) {
      Participant memory participant = listParticipant[i];
      if (passive) {
        _token.safeIncreaseAllowance(participant.account, participant.amount);
      } else {
        _token.safeTransfer(participant.account, participant.amount);
      }
    }
    _campaigns[campaignName].status = CampaignStatus.Release;
    emit Release(campaignName);
  }

  function deleteCampaign(string memory campaignName)
    public
    override
    onlyAdmin
    enoughDeleteConsensus(campaignName)
  {
    require(
      _campaigns[campaignName].status == CampaignStatus.NoAction,
      "Campaign ended!"
    );
    _campaigns[campaignName].status = CampaignStatus.Delete;
    emit DeleteCampaign(campaignName, msg.sender);
  }

  function getDatas() public view override returns (DataByTime[] memory) {
    return _datas;
  }

  function getCampaigns() public view override returns (string[] memory) {
    return _campaignNames;
  }

  function getCampaign(string memory campaignName)
    public
    view
    override
    returns (Campaign memory)
  {
    return _campaigns[campaignName];
  }

  function getTotalTokenUnlock() public view override returns (uint256) {
    return _getTotalTokenUnlock();
  }

  function getTokenCanUse() public view override returns (uint256) {
    return _getTokenCanUse();
  }

  function getConsensusByNameAndStatus(
    string memory campaignName,
    AdminConsentStatus status
  ) public view override returns (uint256) {
    return _getConsensusByNameAndStatus(campaignName, status);
  }

  function getTokenUsed() public view override returns (uint256) {
    return
      _getUsedTokenByStatus(CampaignStatus.NoAction) +
      _getUsedTokenByStatus(CampaignStatus.Release);
  }

  /**
   *@dev
   * Validate input.
   * Requirements:
   *
   * - `campaignName` must not exist.
   * - `_accounts.length` equal `_amounts.length`.
   *
   */
  function _validateTimesAndAmounts(
    uint256[] memory _unlockTimes,
    uint256[] memory _amounts
  ) private pure {
    uint256 numberOfTime = _unlockTimes.length;
    uint256 numberOfAmount = _amounts.length;
    require(
      numberOfTime > 0 && numberOfAmount > 0,
      "Times, accounts can't be zero!"
    );
    require(numberOfTime == numberOfAmount, "Times and accounts not match!");
  }

  /**
   *@dev
   * Validate input.
   * Requirements:
   *
   * - `campaignName` must not exist.
   * - `_accounts.length` equal `_amounts.length`.
   *
   */
  function _validateAccountsAndAmounts(
    address[] memory _accounts,
    uint256[] memory _amounts
  ) private pure {
    uint256 numberOfAccount = _accounts.length;
    uint256 numberOfAmount = _amounts.length;
    require(
      numberOfAccount > 0 && numberOfAmount > 0,
      "Amounts, accounts can't be zero!"
    );
    require(numberOfAccount == numberOfAmount, "Amounts and times not match!");
  }

  /**
   *@dev Set a list of participant to a time and set this participant is true.
   */
  function _createCampaign(
    string memory _campaignName,
    address[] memory _accounts,
    uint256[] memory _amounts,
    uint256 releaseTime,
    bool _isUpdate
  ) private {
    _validateAccountsAndAmounts(_accounts, _amounts);
    _campaignNames.push(_campaignName);

    uint256 totalAmount = 0;
    uint256 tokenCanUse = _getTokenCanUse();
    for (uint256 i = 0; i < _amounts.length; i++) {
      totalAmount += _amounts[i];
    }
    require(tokenCanUse >= totalAmount, "Not enough erc20 token");

    Participant[] storage listParticipant = _campaigns[_campaignName]
      .participants;

    for (uint256 i = 0; i < _accounts.length; i++) {
      listParticipant.push(Participant(_accounts[i], _amounts[i]));
      addNewParticipant(_accounts[i]);
    }

    _campaigns[_campaignName].releaseTime = releaseTime;

    emit ChangeCampaign(_campaignName, _accounts, _amounts, _isUpdate);
  }

  function _adminAcceptRelease(string memory _campaign) private {
    campaignConsents[_campaign][msg.sender] = AdminConsentStatus.Accept;
    emit AdminAcceptRelease(msg.sender, _campaign);
  }

  function _adminRejectRelease(string memory _campaign) private {
    campaignConsents[_campaign][msg.sender] = AdminConsentStatus.Reject;
    emit AdminRejectRelease(msg.sender, _campaign);
  }

  /**
   *@dev Total token in a campaign.
   */
  function _getTokensByName(string memory campaignName)
    private
    view
    returns (uint256)
  {
    uint256 totalToken = 0;
    Participant[] memory listParticipant = _campaigns[campaignName]
      .participants;

    for (uint256 i = 0; i < listParticipant.length; i++) {
      Participant memory participant = listParticipant[i];
      totalToken += participant.amount;
    }
    return totalToken;
  }

  function _getConsensusByNameAndStatus(
    string memory campaignName,
    AdminConsentStatus status
  ) private view returns (uint256 totalCampaignConsensus) {
    uint256 adminsLength = _admins.length;
    for (uint256 i = 0; i < adminsLength; i++) {
      if (campaignConsents[campaignName][_admins[i]] == status) {
        totalCampaignConsensus++;
      }
    }
  }

  function _getTokenCanUse() private view returns (uint256 tokenCanUse) {
    uint256 thisBalance = _token.balanceOf(address(this));
    uint256 tokenUnlock = _getTotalTokenUnlock();
    tokenCanUse = thisBalance < tokenUnlock ? thisBalance : tokenUnlock;
    uint256 tokenMustNotUsed = _getTokenMustNotUsed(thisBalance < tokenUnlock);
    if (tokenCanUse <= tokenMustNotUsed) {
      tokenCanUse = 0;
    } else {
      tokenCanUse -= tokenMustNotUsed;
    }
  }

  /**
   *@dev Total token unlocked.
   */
  function _getTotalTokenUnlock() private view returns (uint256) {
    uint256 totalTokenUnlock = 0;
    uint256 currentTime = block.timestamp;
    for (uint256 i = 0; i < _datas.length; i++) {
      if (currentTime >= _datas[i].unlockTime) {
        totalTokenUnlock += _datas[i].amount;
      }
    }
    return totalTokenUnlock;
  }

  function _getTokenMustNotUsed(bool isCheckBalance)
    private
    view
    returns (uint256 tokenMustNotUsed)
  {
    tokenMustNotUsed = isCheckBalance
      ? _getUsedTokenByStatus(CampaignStatus.NoAction) +
        _getAllowanceOfParticipants()
      : _getUsedTokenByStatus(CampaignStatus.NoAction) +
        _getUsedTokenByStatus(CampaignStatus.Release);
  }

  function _getUsedTokenByStatus(CampaignStatus status)
    private
    view
    returns (uint256 activeToken)
  {
    uint256 campaignLength = _campaignNames.length;
    for (uint256 i = 0; i < campaignLength; i++) {
      string memory name = _campaignNames[i];
      Campaign memory campaign = _campaigns[name];
      Participant[] memory participants = campaign.participants;
      uint256 participantLength = participants.length;
      if (campaign.status == status) {
        for (uint256 j = 0; j < participantLength; j++) {
          Participant memory joiner = participants[j];
          activeToken += joiner.amount;
        }
      }
    }
  }

  function _getAllowanceOfParticipants()
    private
    view
    returns (uint256 activeToken)
  {
    address[] memory addresses = _participants.values;
    uint256 participantLength = addresses.length;
    for (uint256 i = 0; i < participantLength; i++) {
      activeToken += _token.allowance(address(this), addresses[i]);
    }
  }

  function addNewParticipant(address a) public {
    if (!_participants.is_in[a]) {
      _participants.values.push(a);
      _participants.is_in[a] = true;
    }
  }

  function isParticipant(address account) public view returns (bool) {
    return _participants.is_in[account];
  }
}
