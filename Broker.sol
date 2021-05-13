pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import './openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import './openzeppelin/contracts/access/Ownable.sol';
import './MultiToken.sol';
import './utils/TransactionLib.sol';

/** The broker contract */
contract Broker is ERC1155Holder, Ownable {
  using TransactionLib for bytes;

  MultiToken stockBalances;

  function kill() external onlyOwner {
    selfdestruct(payable(_msgSender()));
  }

  // id of NFT to be used for tx validation
  uint256 public validator;

  // address to perform validation
  address public validatorAddress;

  event ChangeValidator(
    address oldValidator,
    address newValidator
  );

  constructor (address addr) {
    stockBalances = MultiToken(addr);
    validator = stockBalances.create(true,0,"",""); // create initial "Validator token"
    validatorAddress = owner();
  }

  // transfer validator privilege to a new address
  function changeValidator(address newValidator) public virtual onlyOwner {
    require(newValidator != address(0), "Ownable: new owner is the zero address");
    emit ChangeValidator(validatorAddress, newValidator);
    validatorAddress = newValidator;
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  )
    public
    override
    returns(bytes4) {
      TransactionLib.Transaction memory txn = TransactionLib.transactionFromBytes(0, data);

      //complete transaction
      if (id == validator) {
        if (txn.success) {
          // complete purchase on success
          stockBalances.mint(
            txn.from,
            txn.toId,
            txn.toAmount,
            data
          );
        } else {
          // revert purchase on failure
          stockBalances.safeTransferFrom(
            address(this),
            txn.from,
            txn.fromId,
            txn.fromAmount,
            ""
          );
        }
      } else { //Initiate transaction
        // mint a validator token with necessary details
        stockBalances.mint(
          validatorAddress,
          validator,
          1,
          data
        );
      }
  }

}