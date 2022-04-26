pragma solidity ^0.8.0;

interface ITimelock {
  function _amount() external returns (uint256);

  function _releaseTime() external returns (uint256);

  function _released() external returns (bool);

  function _token() external returns (address);

  function _createdBy() external returns (address);

  function _recipient() external returns (address);

  function _fee() external returns (uint256);

  function depositEther(uint256 releaseTime_, address recipient) external payable returns (bool);

  function depositERC20(
    uint256 releaseTime_,
    address recipient,
    address token,
    uint256 value_
  ) external returns (bool);

  function setFeePerHour(uint256 fee_) external;

  function proceedWithTx() external;

  function retract() external;
}
