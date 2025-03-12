import "./ownable.tact";

message RemoveToWhitelist {
    address: Address;
}

message AddToWhitelist {
    address: Address;
}


trait WhiteList with Ownable {
    owner: Address;
    list: map<Address, Bool>;

    get fun list(): map<Address, Bool> {
        return self.list;
    }

    fun validListElement(address: Address) {
        let isValid:Bool? = self.list.get(address);

        // Если передаваемый адрес будет адресом owner, то он пропускает проверку
        if(self.owner != address) {
            require(isValid == true, "address not exist");
        }
    }

    receive(msg: RemoveToWhitelist) {
        self.onlyOwner();
        self.list.set(msg.address, false);
    }

    receive(msg: AddToWhitelist) {
        self.onlyOwner();
        self.list.set(msg.address, true);
    }
}