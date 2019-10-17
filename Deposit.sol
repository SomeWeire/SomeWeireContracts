pragma solidity >=0.4.21 <0.6.0;

import "./Owned.sol";
import "./Verify.sol";
import "./Priced.sol";

/*	
	@author	Some Wei're
	@version 1.0

	Main contract for Some Wei're. Contains deposit method, to bury at a location, withdrawal method to dig at a location, check status method to check the status of a buried amount.
	Other methods are owner owned, to set the app address (which ensures deposit withdrawal and status methods can only be called via the mobile app), set the minimum and maximum amount
	to bury, set the transaction price, get the total buried amount (as an event), transfer a deposed amount to an address (help recover a lost amount), and ultimately close
	the contract  
*/

contract Deposit is Owned, Verify, Priced{

	//Map to link an encrypted location with an amount in wei
	mapping(bytes32 => uint256) private funds;

	//Map to link an encrypted location with an owner
	mapping(bytes32 => address) private fundsOwner;

	//Array of buried locations
	bytes32[] private locations;

	//Total of buried treasures in wei
	uint256 private deposedFunds;

	uint256 private price;
	address private appAddress;
	uint256 private etherLimit;
	uint256 private etherMin;

	//Digging Event to validate the transaction on the app side and get the dug amount, with a nonce and the transaction caller indexed as parameters to filter from the app side
	event withdrawalEvent(uint256 indexed timestamp, address indexed sender, uint256 amountFound);
	
	//Deposed Event to validate the transaction on the app side and get the buried amount, with a nonce and the transaction caller indexed as parameters to filter from the app side
	event depositEvent(uint256 indexed timestamp, address indexed sender, uint256 amountDeposed);

	//Total buried amount on the contract, only for the owner
	event deposedBalance(uint256 balance);

	//Check Status event to validate the transaction on the app side and get the buried amount, with an nonce and the transaction caller indexed as parameters to filter from the app side
	event checkFundsStatus(uint256 indexed timestamp, address indexed sender, uint256 fundsAmount);



	/*
	Burying method
	@param _location : encrypted location of the buried amount
	@param _amount : buried amount in wei
	@param _nonce : nonce of the transaction to verify the signature
	@param _appSignature : signature of the app, returned by the Some Wei're API, to ensure this method is only called via the mobile app
	@param _userSignature : signature of the user, to prevent replay attacks
	@return depositEvent : Event to send the amount buried at the location

	The verify modifyer rebuilds user and app signatures to verify addresses of the app and the user, to replay attacks. Go to Verify.sol to get more informations on the verify process
	*/
	function deposit(bytes32 _location, 
					 uint256 _amount,
					 uint256 _nonce, 
					 bytes memory _appSignature,
					 bytes memory _userSignature) public payable verify(_nonce,
					 												_appSignature,
					 												_userSignature,
					 												_location,
					 												_amount,
					 												appAddress,
					 												msg.sender) costs(price){

		//Execution of the method requires the amount to bury to be superior to the value sent by the user
		require(_amount <= msg.value,
				"Failure event due to insufficient funds");

		//Execution of the method requires the value sent to bury to be inferior to the ether limit to be buried
		require(msg.value <= etherLimit,
				"Failure event due to deposed ethers limit exceeded");

		//Execution of the method requires the value sent to bury to be superior to the ether minimum to be buried
		require(msg.value >= etherMin,
				"Failure event due to insufficient ethers to bury");

		//Execution of the method requires the location to be free of any buried treasure
		require(funds[_location] == 0, 
				"Failure event due to ether already buried at location");

		funds[_location] = _amount;

		fundsOwner[_location] = msg.sender;

		locations.push(_location);

		deposedFunds += _amount;

		emit depositEvent(_nonce, msg.sender, _amount);
	}


	/*
	Digging method
	@param _dDX : latitude of the digging position
	@param _dDY : longitude of the digging position
	@param _amount : price paid for the transaction
	@param _nonce : nonce of the transaction to verify the signature
	@param _appSignature : signature of the app, return by the Some Wei're API, to ensure this method is only called via the mobile app
	@param _userSignature : signature of the user, to prevent replay attacks
	@return withdrawalEvent : Event to send the amount found if the location contains a treasure, otherwise sends 0

	The verify modifyer rebuilds user and app signatures to verify addresses of the app and the user, to replay attacks. Go to Verify.sol to get more informations on the verify process
	*/
	function withdrawal(string memory _dDX,
					    string memory _dDY,
					    uint256 _amount,
					    uint256 _nonce, 
					 	bytes memory _appSignature,
					 	bytes memory _userSignature) public payable verify(_nonce, 
					 													_appSignature,
					 													_userSignature,
					 													keccak256(abi.encodePacked(_dDX, _dDY)),
					 													_amount,
					 													appAddress,
					 													msg.sender) costs(price){

		bytes32 location = keccak256(abi.encodePacked(_dDX, _dDY));

		//If the position contains a treasure, the amount is sent to the sender. 
		if(funds[location] > 0){

			uint amountFound = funds[location];

			for(uint i = 0; i < locations.length; i++){
				if(locations[i] == location){
					delete locations[i];
				}
			}

			delete funds[location];

			delete fundsOwner[location];

			deposedFunds -= amountFound;

			msg.sender.transfer(amountFound);

			emit withdrawalEvent(_nonce, msg.sender, amountFound);
		} else {
			emit withdrawalEvent(_nonce, msg.sender, 0);
		}
	}


	/*
	Check Treasures Status method
	@param _location : encrypted location of the buried amount
	@param _nonce : nonce of the transaction to verify the signature
	@param _appSignature : signature of the app, returned by the Some Wei're API, to ensure this method is only called via the mobile app
	@param _userSignature : signature of the user, to prevent replay attacks
	@return checkFundsStatus : Event to send the buried amount if the location contains a treasure or if the user has rights, otherwise sends 0

	The verify modifyer rebuilds user and app signatures to verify addresses of the app and the user, to replay attacks. Go to Verify.sol to get more informations on the verify process
	*/
	function checkDeposedAmountStatus(bytes32 _location,
					 				  uint256 _nonce, 
					 				  bytes memory _appSignature,
					 				  bytes memory _userSignature) public verifyStatus(_nonce, 
					 															 _appSignature,
					 															 _userSignature,
					 															 _location,
					 															 appAddress,
					 															 msg.sender){

		if(fundsOwner[_location] == msg.sender){
			emit checkFundsStatus(_nonce, msg.sender, funds[_location]);
		} else {
			emit checkFundsStatus(_nonce, msg.sender, 0);
		}
	}


	//Fallback method
	function () external payable {
	}

	/*
	Set the app address, which corresponds to the address of the Some Wei're app. This address has to correspond to the address verified via the appSignature sent when calling users methods.
	@param _appAddress : the addess of the app. Set by the owner
	*/
	function setAppAddress(address _appAddress) public onlyOwner {
		appAddress = _appAddress;
	}

	/*
	Set the ether limit and the minium ether in wei to be buried.
	@param _etherLimit : ether limit
	@param _etherLimit : minimum ether value
	*/
	function setEtherLimitAndMinimum(uint256 _etherLimit, uint256 _etherMin) public onlyOwner {
		etherLimit = _etherLimit;
		etherMin = _etherMin;
	}

	/*
	Set the price to be paid when burying or digging
	@param _price : transaction price
	*/
	function setTxPrice(uint256 _price) public onlyOwner {
		price = _price;
	}

	/*
	Get the total of buried treasures, in wei
	*/
	function getDeposedAmount() public onlyOwner {
		emit deposedBalance(deposedFunds);
	}

	/*
	Transfer contracts amount to an address
	@param _appAddress : an addres to send the amount to
	@param _amount : amount to send
	*/
	function transferFundsTo(address payable _appAddress, uint256 _amount) public onlyOwner {
		_appAddress.transfer(_amount);
	}

	/*
	Transfer a buried amount to an address
	@param _appAddress : an addres to send the amount to
	@param _dDX : latitude of the buried treasure
	@param _dDY : longitude of the buried treasure
	*/
	function transferFundsFromDeposedAmountTo(address payable _appAddress, string memory _dDX, string memory _dDY) public onlyOwner {

		bytes32 location = keccak256(abi.encodePacked(_dDX, _dDY));

		if(funds[location] > 0){

			uint amountFound = funds[location];

			for(uint i = 0; i < locations.length; i++){
				if(locations[i] == location){
					delete locations[i];
				}
			}

			delete fundsOwner[location];

			delete funds[location];

			deposedFunds -= amountFound;

			_appAddress.transfer(amountFound);
		}
	}

	/*
	Close the contract by sending all buried amounts to their owners and selfdestructing
	*/
	function close() public onlyOwner {
		address payable appOwnerPayable = address(uint160(owner()));
		for(uint i = 0; i<locations.length; i++){
			if(locations[i] > 0){
				address payable ownerPayable = address(uint160(fundsOwner[locations[i]]));
				ownerPayable.transfer(funds[locations[i]]);
			}
		}
		selfdestruct(appOwnerPayable);
	}
}