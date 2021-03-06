import os
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import compile_starknet_files


async def deploy(starknet, path, params=None):
    params = params or []
    contract_definition = compile_starknet_files([path], debug_info=True)
    deployed_contract = await starknet.deploy(contract_def=contract_definition,constructor_calldata=params)
    return deployed_contract