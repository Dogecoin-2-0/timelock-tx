pragma solidity ^0.8.0;

interface ITimelock {
  function _amount() external returns (uint);
  function _releaseTime() external returns (uint);
  function _released() external returns (bool);
  function _token() external returns (address);
  function releaseToken() external;
}