# ICampaignManagement

## Structs

```solidity

struct DataByTime {
    uint256 unlockTime;
    uint256 amount;
}

```

```solidity
struct Participant {
    address account;
    uint256 amount;
}

```

```solidity
 struct Campaign {
    Participant[] participants;
    CampaignStatus status;
    uint256 releaseTime;
}

```

---
## enums

```solidity

enum AdminConsentStatus {
  NoAction, //default status
  Accept,
  Reject
}

```

```solidity
enum CampaignStatus {
    NoAction,
    Release,
    Delete
}

```

---

## Events

```solidity
    event ChangeCampaign(
    string campaignName,
    address[] accounts,
    uint256[] amounts,
    bool isUpdate
  )
```

```solidity
    event DeleteCampaign(string indexed campaignName, address indexed account)
```

```solidity
    event AdminAcceptRelease(address indexed account, string indexed campaign)
```

```solidity
    event AdminRejectRelease(address indexed account, string indexed campaign)
```

```solidity
    event Release(string campaignName)
```

---

## Functions

### `createCampaign()`

```solidity
    createCampaign(
    string memory campaignName,
    address[] memory accounts,
    uint256[] memory amounts,
    uint256 releaseTime
  ) external
```

### `adminAcceptRelease()`

```solidity
    adminAcceptRelease(string memory campaign) external
```
### `adminRejectRelease()`

```solidity
    adminRejectRelease(string memory campaign) external
```
### `release()`

```solidity
    release(string memory campaignName, bool passive) external
```
### `deleteCampaign()`

```solidity
    deleteCampaign(string memory campaignName) external
```
### `getDatas()`

```solidity
    getDatas() external view returns (DataByTime[] memory)
```
### `getCampaigns()`

```solidity
    getCampaigns() external view returns (string[] memory)
```
### `getConsensusByNameAndStatus()`

```solidity
    getConsensusByNameAndStatus(
    string memory campaignName,
    AdminConsentStatus status
  )
```
### `getCampaign()`

```solidity
    getCampaign(string memory campaignName)
    external
    view
    returns (Campaign memory)
```
### `getTotalTokenUnlock()`

```solidity
    getTotalTokenUnlock() external view returns (uint256)
```
### `getTokenCanUse()`

```solidity
    getTokenCanUse() external view returns (uint256)
```
### `getTokenUsed()`

```solidity
    getTokenUsed() external view returns (uint256)
```