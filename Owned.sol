pragma solidity >=0.4.21 <0.6.0;


/*  
  @author  Some Wei're
  @version 1.0
  
  The Owned contract for Some Wei're. Contains methods to manage ownership of Some Wei're methods
*/
contract Owned {
	constructor() public { _owner = msg.sender; }
    address _owner;

    /*
    OnlyOwner modifyer
    
    The modifyer checks if the sender's address corresponds to the owner's address. If not the transaction is rejected
    */
    modifier onlyOwner {
        require(
            msg.sender == _owner,
            "Only owner can call this function."
        );
        _;
    }

    /*
    Get the onwer's address
    @return _owner : The owner's address
    */
  	function owner() public view returns(address) {
    	return _owner;
  	}

    /*
    Verify if the sender's address is the owner's address
    @return : A boolean to verify if the sender's address is the owner's address
    */
  	function isOwner() public view returns(bool) {
    	return msg.sender == _owner;
  	}

    //OwnershipTransferred Event to get the new owner's address and the previous owner's address 
  	event OwnershipTransferred(
    	address indexed previousOwner,
    	address indexed newOwner
  	);

    /*
    Transfer the ownership of the contract to an address
    @param _newOnwer : The new owner's address
    */
  	function transferOwnership(address _newOwner) public onlyOwner {
    	_transferOwnership(_newOwner);
  	}

    /*
    Process the transfer the ownership of the contract to an address, as an internal function only called within this contract
    @param _newOnwer : The new owner's address
    @return OwnershipTransferred : The event return the new owner's address and the previous owner's address 
    */
  	function _transferOwnership(address _newOwner) internal {
    	require(_newOwner != address(0));
    	emit OwnershipTransferred(_owner, _newOwner);
    	_owner = _newOwner;
  	}
}