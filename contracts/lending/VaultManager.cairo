%lang starknet
%builtins pedersen range_check
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address

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

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func total_shares() -> (res : felt):
end

@storage_var
func erc20_contracts(code : felt) -> (address : felt):
end

@storage_var
func vault_token_address() -> (addr : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    return ()
end

#
# Internal
#

func deposit_to{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        to : felt, currencyCode : felt, amount : felt):
    alloc_locals
    # TODO: Enforce valid currencyCode
    let (local currency_address) = erc20_contracts.read(code=currencyCode)
    let (local price_in_usd) = get_currency_price(currency_address)
    let (local share_supply) = total_shares.read()
    # TODO: Calculate shares to mint based on unclaimed interest thus far (for now assume 1USD is a share)
    let (local vault_address) = vault_token_address.read()
    let shares_transferred : Uint256 = Uint256(price_in_usd, 0)
    let (contract_address) = get_contract_address()

    IERC20.mint(contract_address=vault_address, to=to, amount=shares_transferred)
    IERC20.transferFrom(
        contract_address=vault_address,
        sender=to,
        recipient=contract_address,
        amount=shares_transferred)
    return ()
end

func withdraw_from{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        caller : felt, currency_code : felt, amount : felt, currency_price : felt):
    alloc_locals
    # TODO: Enforce valid currencyCode
    let amount_in_usd = currency_price * amount
    let amount_in_usd_uint : Uint256 = Uint256(amount_in_usd, 0)

    # TODO: calculate value of shares to currency
    let (local vault_address) = vault_token_address.read()
    IERC20.burn(contract_address=vault_address, account=caller, amount=amount_in_usd_uint)

    return ()
end
#
# Externals
#

@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        currency_code : felt, amount : felt):
    alloc_locals
    let (local caller) = get_caller_address()
    deposit_to(caller, currency_code, amount)

    return ()
end

@external
func withdraw{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        currency_code : felt, amount : felt):
    let (local caller) = get_caller_address()
    withdraw_from(caller=caller, currency_code, amount, get_currency_price())
    return ()
end
#
# Stubs (to be implemented elsewhere and removed from this file)
#

func get_currency_price{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token : felt) -> (price : felt):
    return (1)
end
