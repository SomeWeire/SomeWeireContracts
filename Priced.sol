pragma solidity >=0.4.21 <0.6.0;

contract Priced {

    modifier costs(uint256 price) {
        require(msg.value >= price);
         _;
    }
}