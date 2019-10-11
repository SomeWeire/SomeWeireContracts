pragma solidity >=0.4.21 <0.6.0;

import "./Owned.sol";
import "./Verify.sol";
import "./Priced.sol";

contract Deposit is Owned, Verify, Priced{

	mapping(bytes32 => uint256) private funds;
	mapping(bytes32 => address) private fundsOwner;
	bytes32[] private locations;
	uint256 private deposedFunds;
	uint256 private price;
	address private appAddress;
	uint256 private etherLimit;
	uint256 private etherMin;

	event withdrawalEvent(uint256 indexed timestamp, address indexed sender, uint256 amountFound);
	event depositEvent(uint256 indexed timestamp, address indexed sender, uint256 amountDeposed);
	event deposedBalance(uint256 balance);
	event checkFundsStatus(uint256 indexed timestamp, address indexed sender, uint256 fundsAmount);


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

		require(_amount <= msg.value,
				"Failure event due to insufficient funds");

		require(msg.value <= etherLimit,
				"Failure event due to deposed ethers limit exceeded");

		require(msg.value >= etherMin,
				"Failure event due to insufficient ethers to bury");

		require(funds[_location] == 0, 
				"Failure event due to ether already buried at location");

		funds[_location] = _amount;

		fundsOwner[_location] = msg.sender;

		locations.push(_location);

		deposedFunds += _amount;

		emit depositEvent(_nonce, msg.sender, _amount);
	}


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


	function () external payable {
	}

	function setAppAddress(address _appAddress) public onlyOwner {
		appAddress = _appAddress;
	}

	function setEtherLimitAndMinimum(uint256 _etherLimit, uint256 _etherMin) public onlyOwner {
		etherLimit = _etherLimit;
		etherMin = _etherMin;
	}

	function setTxPrice(uint256 _price) public onlyOwner {
		price = _price;
	}

	function getDeposedAmount() public onlyOwner {
		emit deposedBalance(deposedFunds);
	}

	function transferFundsTo(address payable _appAddress, uint256 _amount) public onlyOwner {
		_appAddress.transfer(_amount);
	}

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