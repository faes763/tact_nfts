import "@stdlib/deploy";
import "./helpers/traits/ownable.tact";
import "./helpers/traits/nft/nft-standard.tact";



contract ItemNft with Deployable, NftItemStandard {

    collection_address: Address;
    item_index: Int;

    individual_content: Cell?;

    owner: Address;

    is_initialized: Bool;

    init(collection_address: Address, item_index: Int) {
        require(sender() == collection_address, "not from collection");

        self.collection_address = collection_address;
        self.item_index = item_index;
        self.owner = collection_address;

        self.is_initialized = false;
    }

    

    
    // ---- Getters ---- //


    get fun get_collection_address(): Address {
        return self.collection_address;
    }

    get fun get_item_index(): Int {
        return self.item_index;
    }

}
