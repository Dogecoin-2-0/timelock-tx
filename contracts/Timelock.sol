pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/ITimelock.sol";

contract Timelock is ITimelock, Context {
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

  function proceedWithTx() external {
    _released = true;
  }

  function retract() external {}
}
