%lang starknet
%builtins pedersen range_check
from starkware.cairo.common.uint256 import Uint256, uint256_mul, uint256_unsigned_div_rem
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

@contract_interface
namespace IERC20:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func decimals() -> (decimals : felt):
    end

    func totalSupply() -> (totalSupply : Uint256):
    end

    func balanceOf(account : felt) -> (balance : Uint256):
    end

    func allowance(owner : felt, spender : felt) -> (remaining : Uint256):
    end

    func transfer(recipient : felt, amount : Uint256) -> (success : felt):
    end

    func transferFrom(sender : felt, recipient : felt, amount : Uint256) -> (success : felt):
    end

    func approve(spender : felt, amount : Uint256) -> (success : felt):
    end

    func mint(to : felt, amount : Uint256):
    end

    func burn(account : felt, amount : Uint256):
    end
end

@storage_var
func erc20_contracts(code : felt) -> (address : felt):
end

@storage_var
func pool_token_address() -> (addr : felt):
end

@storage_var
func pool_value() -> (pool_value : Uint256):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        pool_address : felt, input_token_address : felt, initial_pool_value : Uint256):
    pool_token_address.write(pool_address)
    erc20_contracts.write(0, input_token_address)
    pool_value.write(initial_pool_value)

    return ()
end

#
# Internal
#

func deposit_to{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, currency_code : felt, amount : Uint256):
    alloc_locals
    # TODO: Enforce valid currencyCode
    let (local currency_address) = erc20_contracts.read(code=currency_code)
    let (price_in_usd : Uint256) = get_currency_price(currency_address)
    let (usd_depositted : Uint256, of) = uint256_mul(price_in_usd, amount)
    # TODO: Calculate shares to mint based on unclaimed interest thus far (for now assume 1USD is a share)
    let (local pool_address) = pool_token_address.read()
    let (share_supply : Uint256) = IERC20.totalSupply(contract_address=pool_address)

    let (pool_value_uint : Uint256) = pool_value.read()
    let (price_per_share : Uint256, r) = uint256_unsigned_div_rem(share_supply, pool_value_uint)
    let (shares_transferred : Uint256, of) = uint256_mul(price_per_share, usd_depositted)
    let (contract_address) = get_contract_address()

    IERC20.mint(contract_address=pool_address, to=to, amount=shares_transferred)
    IERC20.transferFrom(
        contract_address=pool_address,
        sender=to,
        recipient=contract_address,
        amount=shares_transferred)
    return ()
end

func withdraw_from{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt, currency_code : felt, amount : Uint256, currency_price : Uint256) -> (
        amount : Uint256):
    alloc_locals
    # TODO: Enforce valid currencyCode
    let (amount_in_usd : Uint256, of) = uint256_mul(currency_price, amount)
    let (local pool_address) = pool_token_address.read()
    let (share_supply : Uint256) = IERC20.totalSupply(contract_address=pool_address)
    let (pool_value_uint : Uint256) = pool_value.read()
    let (shares_per_dollar : Uint256, r) = uint256_unsigned_div_rem(share_supply, pool_value_uint)
    let (shares_burn : Uint256, of) = uint256_mul(amount_in_usd, shares_per_dollar)
    # TODO: check share balance of caller is sufficently high
    IERC20.burn(contract_address=pool_address, account=caller, amount=shares_burn)

    let (local withdraw_token_address) = erc20_contracts.read(currency_code)
    IERC20.transfer(contract_address=withdraw_token_address, recipient=caller, amount=amount)
    return (amount_in_usd)
end
#
# Externals
#

@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        currency_code : felt, amount : Uint256):
    alloc_locals
    let (local caller) = get_caller_address()
    deposit_to(caller, currency_code, amount)

    return ()
end

@external
func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        currency_code : felt, amount : Uint256):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local currency_address) = erc20_contracts.read(code=currency_code)

    let (currency_price : Uint256) = get_currency_price(currency_address)
    withdraw_from(
        caller=caller, currency_code=currency_code, amount=amount, currency_price=currency_price)
    return ()
end

@external
func get_pool_token_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (address : felt):
    return pool_token_address.read()
end

@external
func get_address_for_currency_code{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        currency_code : felt) -> (address : felt):
    return erc20_contracts.read(currency_code)
end

@external
func get_pool_value{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        value : Uint256):
    return pool_value.read()
end
#
# Stubs (to be implemented elsewhere and removed from this file)
#

func get_currency_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token : felt) -> (price : Uint256):
    alloc_locals
    let stubbed_price : Uint256 = Uint256(1, 0)
    return (stubbed_price)
end
