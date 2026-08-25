// SPDX-License-Identifier: GPL-3.0

// 01001110 01100101 01110111 01000110 01101001
// 01101110 01100001 01101110 01100011 01100101
// 01001001 01101110 01101001 01110100 01101001
// 01100001 01110100 01101001 01110110 01100101 

import "./Interface_ISA.sol";
import "./SafeMaths.sol";

pragma solidity ^0.8.0; 

contract ISA_EtherBasedOnly_DynamicLimitUnlock {

	using SafeMath for uint256;

	uint256 public MIN_DEPOSIT = 0.000000000000000000 ether;
	uint256 public MAX_DEPOSIT = 120000000 ether;
	uint256 public TARGET_DEPOSIT = 0;
    uint256 public CURRENT_BASIS_POINTS = 0;
	uint256 public FINISH_BASIS_POINTS = 100;

    uint256 public constant STARTING_BASIS_POINTS = 0;
	uint256 public constant PERCENTAGE_BASE = 100;

	uint256 private _balance;
	address private _owner;

	event DepositOfETH(address _from, uint256 _amount);
	event WithdrawalOfETH(address _too, uint256 _amount);
	event ChangeOfOwnership(address _newOwner);

	modifier OnlyOwner() {
        require (msg.sender == _owner);
        _;
    }

	constructor(uint256 _targetDeposit) {
		TARGET_DEPOSIT = _targetDeposit;
		_owner = msg.sender;
	}

	function GetBalance() public OnlyOwner() view returns (uint256) {
        return _balance;
    }

	function DepositEther() public payable {
        require (msg.value >= MIN_DEPOSIT, "Amount is less less than MIN_DEPOSIT");
        require (msg.value <= MAX_DEPOSIT, "Amount is greater than MAX_DEPOSIT");
        _balance = _balance.add(msg.value);
		BasisPointMeasurement(msg.value);
        emit DepositOfETH(msg.sender, msg.value);
    }

	function WithdrawEther(address _too, uint256 _amount) public payable OnlyOwner() {
        require (_amount != 0, "Amount is equal to zero");
		payable(_too).transfer(_amount);
        WithdrawAmountMeasurement(_too, _amount);
        emit WithdrawalOfETH(_too, _amount);
    }

	function BasisPointMeasurement(uint256 _amount) internal returns (uint256) {
		uint256 _basis_points =  _amount.div(TARGET_DEPOSIT).mul(PERCENTAGE_BASE);
		CURRENT_BASIS_POINTS = CURRENT_BASIS_POINTS + _basis_points;
		require (FINISH_BASIS_POINTS >= CURRENT_BASIS_POINTS, "Basis point limit has been reached!");
		return (CURRENT_BASIS_POINTS);
	}

	function RemoveBasisPoints(uint256 _amount) internal returns (uint256) {
		CURRENT_BASIS_POINTS = _amount.mul(PERCENTAGE_BASE).div(TARGET_DEPOSIT);
		return CURRENT_BASIS_POINTS;
	}

	function WithdrawAmountMeasurement(address _too, uint256 _amount) internal returns (bool, uint256) {
		uint256 _withdrawAmount = CURRENT_BASIS_POINTS.div(PERCENTAGE_BASE).mul(_balance);
		require (_withdrawAmount <= FINISH_BASIS_POINTS, "Amount is greater than calculated withdrawal limit");
		payable(_too).transfer(_amount);
		_balance = _balance.sub(_amount);
		RemoveBasisPoints(_amount);
		return (true, _withdrawAmount);
	}

	function ChangeOwner(address _newOwner) public OnlyOwner() {
        _owner = _newOwner;
        emit ChangeOfOwnership(_newOwner);
    }

}
