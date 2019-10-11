pragma solidity >=0.4.21 <0.6.0;

contract Owned {
	constructor() public { _owner = msg.sender; }
    address _owner;

    modifier onlyOwner {
        require(
            msg.sender == _owner,
            "Only owner can call this function."
        );
        _;
    }

  	function owner() public view returns(address) {
    	return _owner;
  	}

  	function isOwner() public view returns(bool) {
    	return msg.sender == _owner;
  	}

  	event OwnershipTransferred(
    	address indexed previousOwner,
    	address indexed newOwner
  	);

  	function transferOwnership(address _newOwner) public onlyOwner {
    	_transferOwnership(_newOwner);
  	}

  	function _transferOwnership(address _newOwner) internal {
    	require(_newOwner != address(0));
    	emit OwnershipTransferred(_owner, _newOwner);
    	_owner = _newOwner;
  	}
}