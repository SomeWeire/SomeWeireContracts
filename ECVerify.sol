pragma solidity >=0.4.21 <0.6.0;


/*  
  @author  Some Wei're
  @version 1.0
  
  ECRecovery library, to recover an address from an eliptic curve signature
  @param hash : the hash, informations contained in the signature, before signing it with the private key 
  corresponding to the address
  @param sig : the signature, the hash signed with the private key corresponding to the address
*/
library ECRecovery {
  function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return (address(0));
    }

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }
}