import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode
from utils import Signer, uint, str_to_felt, MAX_UINT256

signer = Signer(123456789987654321)


@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope='module')
async def erc20_factory():
    starknet = await Starknet.empty()
    account = await starknet.deploy(
        "./contracts/erc20/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    erc20 = await starknet.deploy(
        "./contracts/erc20/ERC20.cairo",
        constructor_calldata=[
            str_to_felt("Token"),      # name
            str_to_felt("TKN"),        # symbol
            *uint(1000),               # initial_supply
            account.contract_address   # recipient
        ]
    )
    return starknet, erc20, account


@pytest.fixture(scope='module')
async def pool_manager_factory():
    starknet = await Starknet.empty()

    account = await starknet.deploy(
        "./contracts/erc20/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    input_token = await starknet.deploy(
        "./contracts/erc20/ERC20.cairo",
        constructor_calldata=[
            str_to_felt("Token"),      # name
            str_to_felt("TKN"),        # symbol
            *uint(1000),               # initial_supply
            account.contract_address   # recipient
        ]
    )

    pool_token = await starknet.deploy(
        "./contracts/erc20/Ownable_ERC20.cairo",
        constructor_calldata=[
            str_to_felt("Our Pool"),      # name
            str_to_felt("POOL"),        # symbol
            *uint(1000),               # initial_supply
            account.contract_address   # recipient & owner
        ]
    )

    pool_manager = await starknet.deploy(
        "./contracts/lending/PoolManager.cairo",
        constructor_calldata=[
            signer.public_key,
            pool_token.contract_address,  # pool_address
            input_token.contract_address,  # input_token_address
            * uint(0)  # initial_pool_value
        ]
    )

    await signer.send_transaction(account, pool_token.contract_address, 'transferOwnership', [
        pool_manager.address
    ])

    return starknet, account, input_token, pool_token, pool_manager


@pytest.mark.asyncio
async def test_deploying_a_pool(pool_manager_factory):
    _, account, input_token, pool_token, pool_manager = pool_manager_factory
    execution_info = await pool_manager.get_pool_token_address(account.contract_address).call()
    assert execution_info.result.balance == pool_token.contract_address
