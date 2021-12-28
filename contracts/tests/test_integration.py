import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.definitions.error_codes import StarknetErrorCode
from utils import Signer, uint, str_to_felt, MAX_UINT256

signer = Signer(123456789987654321)
guardian_signer = Signer(456789987654321123)


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
async def integration_factory():
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
            *uint(100),               # initial_supply
            account.contract_address   # recipient & owner
        ]
    )

    pool_manager = await starknet.deploy(
        "./contracts/lending/PoolManager.cairo",
        constructor_calldata=[
            pool_token.contract_address,  # pool_address
            input_token.contract_address,  # input_token_address
            *uint(0)  # initial_pool_value
        ]
    )

    await signer.send_transaction(account, pool_token.contract_address, 'transferOwnership', [
        pool_manager.contract_address
    ])

    await signer.send_transaction(account, input_token.contract_address, 'transfer', [
        pool_manager.contract_address,
        *uint(100)
    ])

    guardian = await starknet.deploy("./contracts/walllet/guardians/SCSKGuardian.cairo", [guardian_signer.public_key])
    user_1 = await starknet.deploy(
        "./contracts/wallet/ArgentAccount.cairo",
        constructor_calldata=[signer.public_key, guardian.contract_address]
    )

    await signer.send_transaction(account, user_1.contract_address, 'setYeildProvider', [
        pool_manager.contract_address
    ])

    await signer.send_transaction(account, user_1.contract_address, 'addLendingToken', [
        input_token.contract_address
    ])

    guardian_2 = await starknet.deploy("./contracts/walllet/guardians/SCSKGuardian.cairo", [guardian_signer.public_key])
    user_2 = await starknet.deploy(
        "./contracts/wallet/ArgentAccount.cairo",
        constructor_calldata=[signer.public_key, guardian_2.contract_address]
    )

    await signer.send_transaction(account, user_2.contract_address, 'setYeildProvider', [
        pool_manager.contract_address
    ])

    await signer.send_transaction(account, user_2.contract_address, 'addLendingToken', [
        input_token.contract_address
    ])

    return starknet, account, input_token, pool_token, pool_manager, user_1, guardian, user_2, guardian_2


@pytest.mark.asyncio
async def test_deploying(integration_factory):
    _, erc20_owner, input_token, pool_token, pool_manager, user_1, guardian_1, user_2, guardian_2 = integration_factory
    assert 1

# setup
# deploy erc20_owner contract
# deploy ERC 20
    # mint an initial 1000 tokens
# deploy pool token, erc20_owner recieves 100 shares
# deploy pool manager with pool_token as owned token and an initial dollar value of 100 usd
    # erc20_owner transfers 100 tokens to pool_manager
# erc20_owner sets owner of pool_token to pool_manager

# create user_1 account
    # set yield_provider_address of user_1 to pool_manager.contract_address
    # add erc20 as lending token
# create user_2 account
    # set yield_provider_address of user_2 to pool_manager.contract_address
    # add erc20 as lending token

# scenario 1 : user_1 recieves erc_20 tokens and puts them into a lending pool
# erc20_owner transfer 10 of it's erc20 tokens to user_1
# ASSERT that user_1 owns shares of lending pool

# scenario 2 : user_1 sends their tokens to a new user
# increase the dollar value of the lending pool manually
# user_1 calls transfer for 10 tokens from erc_20 with the recipient user_2
# should observe that user_1 has remaining balance in lending_pool
# observe user_2 has shares in lending pool
