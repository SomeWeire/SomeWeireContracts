pragma solidity >=0.4.21 <0.6.0;

/*  
  @author  Some Wei're
  @version 1.0
  
  The Prices contract, containing a modifier to verify the price of a transaction. 
*/
contract Priced {

	/*
    Priced modifyer
    @param price : Price of the transaction
    
    The modifyer checks if a transactions value is superior to the price set by the owner. 
    If not the transaction is rejected
    */
    modifier costs(uint256 price) {
        require(msg.value >= price);
         _;
    }
}