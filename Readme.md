# Yield Wallet Proof of Concept for Starknet

The purpose of this repo is to prototype a StarkNet wallet that has additional defi features for a better user expirence. The protype focuses on transfering tokens and putting tokens into lending pools

The approach in this repo is to add two features to the Account contract.
1. Add a selector listener for transfer calls in the 'execute' method. When a transfer call is additional actions are preformed such as withdrawing from the lending pool.
2. Add a 'recieved' external method to the Account contract. This method can be called by token contracts to trigger additional actions such as depositing to a lending pool.

## Lessons Learned

This project showed how easily additional logic could be added to an argent account contract. However these methods are not flexible enough for other types of actions. Additionally this project tampers with the ERC* standard. 

On the consumer side of this interface (the token contract) the contract has no way to know wether the recieving contract account has isRecieved which is a breaking change. 

A future iteration of this project should seek to find a way to add flexible automation to the Account Contract without requiring signifigant changes by the consumer.

compiling contracts - nile compile

running tests:
'erc20' : from project root - pytest contracts/erc20/tests/test_ERC20.py

