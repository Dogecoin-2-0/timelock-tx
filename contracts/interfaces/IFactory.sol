pragma solidity ^0.8.0;

interface IFactory {
  event TimelockDeployed(address timelock, uint256 timestamp, address owner, address token, uint256 deposited);
}
