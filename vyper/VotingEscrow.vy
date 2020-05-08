from vyper.interfaces import ERC20

token: public(address)
balances: public(map(address, uint256))
unlock_times: public(map(address, timestamp))
supply: public(uint256)


@public
def __init__(token_addr: address):
    self.token = token_addr
    self.supply = 0


@private
def _checkpoint(addr: address, old_value: uint256, old_supply: uint256):
    pass


@public
@nonreentrant('lock')
def deposit(value: uint256, unlock_time: timestamp = 0):
    # Also used to extent locktimes
    old_unlock_time: timestamp = self.unlock_times[msg.sender]
    old_value: uint256 = self.balances[msg.sender]
    old_supply: uint256 = self.supply

    if unlock_time == 0:
        assert old_value > 0, "No existing stake found"
        assert old_unlock_time > block.timestamp, "Time to unstake"
    else:
        if old_value > 0:
            assert unlock_time >= old_unlock_time, "Cannot make locktime smaller"
        assert unlock_time > block.timestamp, "Can only lock until time in the future"

    self._checkpoint(msg.sender, old_value, old_supply)

    self.balances[msg.sender] = old_value + value
    self.supply = old_supply + value
    if unlock_time > 0:
        self.unlock_times[msg.sender] = unlock_time

    assert_modifiable(ERC20(self.token).transferFrom(msg.sender, self, value))
    # XXX logs


@public
@nonreentrant('lock')
def withdraw(value: uint256):
    assert block.timestamp >= self.unlock_times[msg.sender]

    old_value: uint256 = self.balances[msg.sender]
    old_supply: uint256 = self.supply

    self._checkpoint(msg.sender, old_value, old_supply)

    self.balances[msg.sender] = old_value - value
    self.supply = old_supply - value

    assert_modifiable(ERC20(self.token).transfer(msg.sender, value))
    # XXX logs


# The following ERC20/minime-compatible methods are not real balanceOf and supply!
# They measure the weights for the purpose of voting, so they don't represent
# real coins.

@public
def balanceOf(addr: address) -> uint256:
    return 0


@public
def balanceOfAt(addr: address, _block: uint256) -> uint256:
    return 0


@public
def totalSupply() -> uint256:
    return 0


@public
def totalSupplyAt(_block: uint256) -> uint256:
    return 0
