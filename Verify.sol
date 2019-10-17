pragma solidity >=0.4.21 <0.6.0;

import "./ECVerify.sol";

/*  
  @author  Some Wei're
  @version 1.0
  
  The Verify contract, containing modifiers to verify the signatures of the app address, ensuring the method has been called from the mobile app, and the users address, to prevent replay
  attacks. 
*/

contract Verify {

    //A mapping containing all nonces that have been received from an address and a flag. Addresses can't replay a previous transaction.
    mapping(address => mapping(uint256 => bool)) private seenNonces;

    /*
    Verify modifyer
    @param _nonce : nonce of the transaction to verify the signature. The nonce prevents replay attacks. Nonces are incremented and stored in the contract
    @param _appSignature : signature of the app, returned by the Some Wei're API, to ensure a method is only called via the mobile app
    @param _userSignature : signature of the user, to prevent replay attacks
    @param _location : encrypted location of the buried amount
    @param _amount : amount in wei (buried amount for the bury transaction or price for the dig transaction)
    @param _appAddress : the address of the app to ensure a method is only called via the mobile app
    @param _sender : the address of the transaction sender
    
    */
    modifier verify(uint256 _nonce,
    				bytes memory _appSignature,
                    bytes memory _userSignature,
    				bytes32 _locationHash,
    				uint256 _amount,
    				address _appAddress,
                    address _sender){


        //If the nonce has already been stored in the contract or if the addresses recovered from the user and app signatures don't correspond to their signatures, the transaction is rejected
        require((!seenNonces[_sender][_nonce]) && (ECRecovery.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
        																			keccak256(abi.encodePacked(_locationHash, 
        																										_amount, 
        																										_nonce)))), 
        												                                                        _appSignature) == _appAddress)
                                               && (ECRecovery.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
                                                                                    keccak256(abi.encodePacked(_locationHash,
                                                                                                                _amount, 
                                                                                                                _nonce)))), 
                                                                                                                _userSignature) == _sender));
        //The nonce from the sender is stored in the array of array and is flagged as true
        seenNonces[_sender][_nonce] = true;
        _;
    }

    /*
    Verify Status modifyer
    @param _nonce : nonce of the transaction to verify the signature. The nonce prevents replay attacks. Nonces are incremented and stored in the contract
    @param _appSignature : signature of the app, returned by the Some Wei're API, to ensure a method is only called via the mobile app
    @param _userSignature : signature of the user, to prevent replay attacks
    @param _location : encrypted location of the buried amount
    @param _appAddress : the address of the app to ensure a method is only called via the mobile app
    @param _sender : the address of the transaction sender
    
    The modifyer is the same has the verify modifyer, without the amount as a param, as the check status transaction doesn't contain an amount as a param
    */
    modifier verifyStatus(uint256 _nonce,
                    bytes memory _appSignature,
                    bytes memory _userSignature,
                    bytes32 _locationHash,
                    address _appAddress,
                    address _sender){


        require((!seenNonces[_sender][_nonce]) && (ECRecovery.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
                                                                                    keccak256(abi.encodePacked(_locationHash,
                                                                                                                _nonce)))), 
                                                                                                                _appSignature) == _appAddress)
                                               && (ECRecovery.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
                                                                                    keccak256(abi.encodePacked(_locationHash,
                                                                                                                _nonce)))), 
                                                                                                                _userSignature) == _sender));
        seenNonces[_sender][_nonce] = true;
        _;
    }
}