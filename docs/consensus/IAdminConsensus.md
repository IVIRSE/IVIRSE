# IAdminConsensus

## enums

```solidity
enum ConsentStatus {
  NoAction, //default status
  Accept,
  Reject
}

```

---

## Events

```solidity
    event AddAdmin(address indexed performer, address indexed newAdmin)
```

```solidity
    event RemoveAdmin(address indexed performer, address indexed adminRemoved)
```

```solidity
    event AdminAccept(address indexed admin, address newAdmin)
```

```solidity
    event AdminReject(address indexed admin, address newAdmin)
```

---

## Functions

### `addAdmin()`

```solidity
    addAdmin(address account) external
```

### `revokeAdminRole()`

```solidity
    revokeAdminRole(address account) external
```
### `renounceAdminRole()`

```solidity
    renounceAdminRole() external
```
### `adminAccept()`

```solidity
    adminAccept(address account) external
```
### `adminReject()`

```solidity
    adminReject(address account) external
```
### `getAdminConsensusByAddressAndStatus()`

```solidity
    getAdminConsensusByAddressAndStatus(address account, ConsentStatus status) external view
```
### `getAdmins()`

```solidity
    getAdmins() external view returns (address[] memory)
```