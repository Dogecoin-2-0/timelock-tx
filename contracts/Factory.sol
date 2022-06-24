pragma solidity ^0.8.0;

import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Factory is IFactory, Context, ReentrancyGuard, AccessControl {
  using SafeMath for uint256;

  mapping(bytes32 => TimelockObject) private _timelocks;
  address private _feeTaker;

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only admin");
    _;
  }

  constructor(address feeTaker_) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _feeTaker = feeTaker_;
  }

  // Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint256 x) private pure returns (uint256 y) {
    uint256 _x = x;
    uint256 _y = 1;

    while (_x - _y > uint256(0)) {
      _x = (_x + _y) / 2;
      _y = x / _x;
    }
    y = _x;
  }

  function _calculateFee(
    uint256 lockTime_,
    uint256 amount_,
    address _recipient
  ) public view returns (uint256) {
    require(
      lockTime_.sub(block.timestamp) >= 5 minutes,
      "difference between lock time and current block time should be at least 5 minutes"
    );
    return sqrt(amount_.mul(lockTime_.div(block.timestamp)).div(uint256(uint160(_recipient))));
  }
}
