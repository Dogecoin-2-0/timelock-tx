pragma solidity ^0.8.0;

import "./Timelock.sol";
import "./interfaces/IFactory.sol";

contract Factory is IFactory {
  function deployTimelockContract() external returns (address timelock) {
    bytes memory byteCode = type(Timelock).creationCode;
  }
}
