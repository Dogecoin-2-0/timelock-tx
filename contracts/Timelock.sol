pragma solidity ^0.8.0;

import './interfaces/ITimelock.sol';

contract Timelock is ITimelock {
  uint public _amount;
  uint public _releaseTime;
  bool public _released;
  address public _token;
  
  constructor(uint amount_, uint releaseTime_, address token_) {
    _amount = amount_;
    _releaseTime = releaseTime_;
    _token = token_;
  }

  function releaseToken() external {
    _released = true;
  }
}