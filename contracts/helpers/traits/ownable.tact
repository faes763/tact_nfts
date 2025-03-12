
message TransferOwnership {
    new_owner: Address;
}

trait Ownable {

    owner: Address;

    fun onlyOwner() {
        require(self.owner == sender(), "Only owner");
    }

    get fun get_owner(): Address {
        return self.owner;
    }

    receive(msg: TransferOwnership) {
        self._transferOwnerShip(msg.new_owner);
    }

    virtual fun _transferOwnerShip(new_owner: Address) {
        self.onlyOwner();
        self.owner = new_owner;
    }


}