pragma solidity ^0.8.0;

import "./interfaces/IFactory.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Factory is IFactory, Context, ReentrancyGuard, AccessControl {
  using SafeMath for uint256;

  mapping(bytes32 => TimelockObject) private _timelocks;

  // Keep record of untouchable token balances to prevent withdrawal
  mapping(address => uint256) private _lockedTokenBalances;
  address private _feeTaker;
  uint256 private _withdrawableFee;

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

  function _safeTransferFrom(
    address token_,
    address owner_,
    address recipient_,
    uint256 amount_
  ) private returns (bool) {
    (bool success, ) = token_.call(
      abi.encodeWithSelector(
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)"))),
        owner_,
        recipient_,
        amount_
      )
    );
    require(success, "could not transfer token");
    return true;
  }

  function _safeTransfer(
    address token_,
    address recipient_,
    uint256 amount_
  ) private returns (bool) {
    (bool success, ) = token_.call(
      abi.encodeWithSelector(bytes4(keccak256(bytes("transfer(address,uint256)"))), recipient_, amount_)
    );
    require(success, "could not transfer token");
    return true;
  }

  function _safeTransferETH(address to_, uint256 amount_) private returns (bool) {
    uint256 balance = address(this).balance;
    require(balance >= amount_, "balance too low");
    (bool success, ) = to_.call{value: amount_}(new bytes(0));
    require(success, "could not transfer ether");
    return true;
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

  function _lockTokenForLater(
    address token_,
    uint256 lockTime_,
    address recipient_,
    uint256 amount_
  ) external payable {
    require(
      lockTime_.sub(block.timestamp) >= 5 minutes,
      "difference between lock time and current block time should be at least 5 minutes"
    );
    require(IERC20(token_).allowance(_msgSender(), address(this)) >= amount_, "allowance too low");
    uint256 _fee = _calculateFee(lockTime_, amount_, _msgSender());
    require(msg.value >= _fee, "must pay exact fee");
    bytes32 _timelockID = keccak256(
      abi.encodePacked(lockTime_, amount_, recipient_, _msgSender(), _fee, block.timestamp)
    );
    _safeTransferFrom(token_, _msgSender(), address(this), amount_);
    _lockedTokenBalances[token_] = amount_;
    _timelocks[_timelockID] = TimelockObject({
      _id: _timelockID,
      _amount: amount_,
      _creator: _msgSender(),
      _recipient: recipient_,
      _token: token_,
      _lockedUntil: lockTime_,
      _fee: _fee
    });
    emit TimelockObjectCreated(_timelockID, amount_, _msgSender(), recipient_, token_, lockTime_, _fee);
  }

  function proceedWithTx(bytes32 _timelockID) external returns (bool) {
    TimelockObject storage timelockObj = _timelocks[_timelockID];
    require(timelockObj._creator == _msgSender() && timelockObj._id != 0x00, "invalid request");

    if (timelockObj._token == address(0)) {
      _safeTransferETH(timelockObj._recipient, timelockObj._amount.sub(timelockObj._fee));
      _withdrawableFee = _withdrawableFee.add(timelockObj._fee);
    } else {
      _safeTransfer(timelockObj._token, timelockObj._recipient, timelockObj._amount);
      _lockedTokenBalances[timelockObj._token] = _lockedTokenBalances[timelockObj._token].sub(timelockObj._amount);
      _withdrawableFee = _withdrawableFee.add(timelockObj._fee);
    }

    timelockObj._creator = address(0);
    timelockObj._id = 0x00;
    timelockObj._amount = 0;
    timelockObj._recipient = address(0);
    timelockObj._fee = 0;

    return true;
  }
}
