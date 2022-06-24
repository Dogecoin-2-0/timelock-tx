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
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
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

  function _lockEtherForLater(uint256 lockTime_, address recipient_) external payable {
    require(
      lockTime_.sub(block.timestamp) >= 5 minutes,
      "difference between lock time and current block time should be at least 5 minutes"
    );
    uint256 _fee = _calculateFee(lockTime_, msg.value, _msgSender());
    bytes32 _timelockID = keccak256(
      abi.encodePacked(lockTime_, msg.value, recipient_, _msgSender(), _fee, block.timestamp)
    );
    _timelocks[_timelockID] = TimelockObject({
      _id: _timelockID,
      _amount: msg.value,
      _creator: _msgSender(),
      _recipient: recipient_,
      _token: address(0),
      _lockedUntil: lockTime_,
      _fee: _fee
    });
    emit TimelockObjectCreated(_timelockID, msg.value, _msgSender(), recipient_, address(0), lockTime_, _fee);
  }
}
