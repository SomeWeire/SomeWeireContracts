pragma solidity >=0.4.21 <0.6.0;

import "./ECVerify.sol";

contract Verify {

    mapping(address => mapping(uint256 => bool)) private seenNonces;

    modifier verify(uint256 _nonce,
    				bytes memory _appSignature,
                    bytes memory _userSignature,
    				bytes32 _locationHash,
    				uint256 _amount,
    				address _appAddress,
                    address _sender){


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
        seenNonces[_sender][_nonce] = true;
        _;
    }

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