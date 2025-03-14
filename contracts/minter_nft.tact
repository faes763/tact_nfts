import "@stdlib/deploy";
import "./helpers/traits/nft/nft-standard.tact";
import "./helpers/traits/whitelist.tact";
import "./helpers/traits/stoppable.tact";
import "./helpers/traits/ownable.tact";
import "./helpers/traits/helpers.tact";
import "./helpers/messages.tact";

import "./item_nft.tact";

contract MinterNft with Deployable, Ownable, WhiteList, Stoppable, Helpers, NftRoyalty {

    owner: Address;

    numerator: Int;
    denominator: Int;
    destination: Address;

    // Collection
    next_item_index: Int as uint64 = 0;
    collection_content: Cell;   

    price: Int = ton("0.01");

    // trait whitelist
    list: map<Address, Bool>;


    // trait stoppable
    mint_blocked: Bool = false;
    time_passed: Int = 0;
    
    init(
        collection_content: Cell,
        price: Int?,
        numerator: Int,
        denominator: Int,
        destination: Address,
    ) {

        // владельцем контракта становится создавший коллекцию
        self.owner = sender();

        // информация о коллекции
        self.collection_content = collection_content;

        if(price != null) {
            self.price = price!!;
        }

        self.numerator = numerator;
        self.denominator = denominator;
        self.destination = destination;
    }

    receive(msg: FreeMint) {

        self.onlyOwner();
        self.validListElement(sender());


        if(msg.to_address == null) {
            self.mint(sender());
        } else {
            self.mint(msg.to_address!!);
        }
    }

    receive(msg: ChangePrice) {
        self.onlyOwner();
        self.price = msg.new_price;
    }

    receive(msg: FreeManyMint) {
        self.onlyOwner();
        self.validListElement(sender());

        let i: Int = 0;

        repeat (msg.length) {
            let to: Address? = msg.to_addresses.get(i);
            i += 1;
            if(to != null) {
                self.mint(to!!);
            }
        }
    }


    receive("Mint") {
        require(self.price <= context().value, "Not enough money");
        
        self.mint(sender());
    }

    // Нужно для того чтобы можно было отправлять ton на контракт
    receive() {}




    fun mint(to_mint: Address) {
        // Проверка может ли пользователь минтить
        self.canMint(); 

        let nft_init = self.get_nft_init_by_index(self.next_item_index);
        send(SendParameters{
            to: contractAddress(nft_init),
            // Нужно для активации контракта
            // value: max(ton("0.05"), self.price / 2),
            value: ton("0.08"),
            bounce: false,
            mode: SendIgnoreErrors,
            body: Transfer{
                query_id: 0,
                new_owner: to_mint,
                response_destination: self.owner,
                custom_payload: self.collection_content,
                forward_amount: 0,
                forward_payload: emptySlice()
            }.toCell(),
            code: nft_init.code,
            data: nft_init.data
        });

        self.next_item_index = self.next_item_index + 1;

    }




    // ---- Getters ---- //

    // Получение информации о коллекции
    get fun get_collection_data(): CollectionData {     
        return CollectionData{
            next_item_index: self.next_item_index, 
            collection_content: self.collection_content, 
            owner_address: self.owner
        };
    }

    // Получение StateInit NFT по индексу
    get fun get_nft_init_by_index(item_index: Int): StateInit {
        return initOf ItemNft(myAddress(), item_index);
    }

    // Получение адреса NFT по индексу
    get fun get_nft_address_by_index(item_index: Int): Address {
        return contractAddress(self.get_nft_init_by_index(item_index));
    }

    // Для получения текущего индекса
    get fun current_index(): Int {
        return self.next_item_index;
    }




}
