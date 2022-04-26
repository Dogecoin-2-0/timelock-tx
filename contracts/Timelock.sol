pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ITimelock.sol";

contract Timelock is ITimelock, Context {
  using SafeMath for uint256;

  uint256 public _amount;
  uint256 public _releaseTime;
  bool public _released;
  address public _token;
  address public _createdBy;
  address public _recipient;
  uint256 public _fee;

  address _deployer;

  modifier onlyDeployer() {
    require(_msgSender() == _deployer, "FORBIDDEN");
    _;
  }

  constructor() {
    _deployer = _msgSender();
  }

  function setFeePerHour(uint256 fee_) external onlyDeployer {
    require(fee_ > 0, "FEE_MUST_BE_GREATER_THAN_0");
    _fee = fee_;
  }

  function depositEther(uint256 releaseTime_, address recipient_) external payable returns (bool) {
    _releaseTime = releaseTime_;
    _amount = msg.value;
    _token = address(0);
    _createdBy = _msgSender();
    _recipient = recipient_;
    return true;
  }

  function depositERC20(
    uint256 releaseTime_,
    address recipient,
    address token,
    uint256 value_
  ) external returns (bool) {
    require(IERC20(token).allowance(_msgSender(), address(this)) >= value_, "no allowance");
    require(_safeTransferFrom(token, _msgSender(), recipient, value_), "could not safely transfer tokens");
    _releaseTime = releaseTime_;
    _amount = value_;
    _token = token;
    _createdBy = _msgSender();
    _recipient = recipient;
    return true;
  }

  function _safeTransferFrom(
    address token_,
    address sender_,
    address recipient_,
    uint256 value_
  ) private returns (bool) {
    (bool success, bytes memory data) = token_.call(
      abi.encodeWithSelector(
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)"))),
        sender_,
        recipient_,
        value_
      )
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), "could not safely transfer tokens");
    return true;
  }

  function _safeTransfer(
    address token_,
    address to_,
    uint256 value_
  ) private returns (bool) {
    (bool success, bytes memory data) = token_.call(
      abi.encodeWithSelector(bytes4(keccak256(bytes("transfer(address,uint256)"))), to_, value_)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), "could not safely transfer tokens");
    return true;
  }

  function _safeTransferETH(address to_, uint256 value_) private returns (bool) {
    (bool success, ) = to_.call{value: value_}(new bytes(0));
    require(success, "could not safely transfer ether");
    return true;
  }

  function proceedWithTx() external {
    require(!_released, "transaction already executed");

    if (_token == address(0)) {
      require(address(this).balance >= _amount, "balance too low");
      require(_safeTransferETH(_recipient, _amount), "could not safely transfer ether");
    } else {
      require(IERC20(_token).balanceOf(address(this)) >= _amount, "balance too low");
      require(_safeTransfer(_token, _recipient, _amount), "could not safely transfer tokens");
    }
    _amount = 0;
    _released = true;
  }

  function retract() external {
    require(block.timestamp < _releaseTime, "can only cancel before release time");

    if (_token == address(0)) {
      require(_safeTransferETH(_createdBy, _amount.add(_fee)));
    } else {
      require(_safeTransfer(_token, _createdBy, _amount));
      require(_safeTransferETH(_createdBy, _fee));
    }
  }
}
