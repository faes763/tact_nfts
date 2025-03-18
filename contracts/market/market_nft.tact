import "@stdlib/deploy";
import "../helpers/traits/ownable.tact";
import "../helpers/messages.tact";

import "../minter_nft.tact";
import "../item_nft.tact";
import "./sale_nft.tact";
import "./market_item.tact";

contract MarketNft with Deployable, Ownable {

    owner: Address;

    marketplace_fee_address: Address?; 
    marketplace_fee: Int;

    next_item_index: Int as uint64 = 0;

    init(marketplace_fee: Int, marketplace_fee_address: Address?) {
        self.owner = sender();

        self.marketplace_fee = marketplace_fee;

        self.marketplace_fee_address = marketplace_fee_address;
    }

    receive(msg: CreateMarketItemFromOther) {
        let market_item_init: StateInit = self.get_market_item_state(self.next_item_index);

        send(SendParameters{
            to: contractAddress(market_item_init),
            value: 0,
            mode: SendRemainingValue,
            body: ProvideSaleNft{
                nft_sale_address: msg.nft_sale_address,
                full_price: 0,
                nft_address: newAddress(0, 0),
            }.toCell(),
            code: market_item_init.code,
            data: market_item_init.data,
        });

        self.next_item_index = self.next_item_index + 1;
    }

    fun fromSlice(s: Slice): ItemData {
        return ItemData{
            full_price: s.loadCoins() 
        };
    }

    receive(msg: OwnershipAssigned) {
        let market_item_init: StateInit = self.get_market_item_state(self.next_item_index);

        let data: ItemData = self.fromSlice(msg.forward_payload);


        send(SendParameters{
            to: contractAddress(market_item_init),
            value: ton("0.15"),
            body: ProvideSaleNft{
                nft_sale_address: null,
                full_price: data.full_price,
                nft_address: sender(),
            }.toCell(),
            code: market_item_init.code,
            data: market_item_init.data,
        });

        let sale_init: StateInit = initOf SaleNft(myAddress(), sender(), data.full_price, self.marketplace_fee_address, self.marketplace_fee);


        send(SendParameters{
            to: sender(),
            value: ton("0.15"),
            body: Transfer{
                query_id: now(),
                new_owner:  contractAddress(sale_init),
                response_destination: myAddress(),
                custom_payload: emptyCell(),
                forward_amount: ton("0.05"),
                forward_payload: emptySlice()
            }.toCell(),
        });

        self.next_item_index = self.next_item_index + 1;
    }



    receive(msg: GetMarketParams) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: ReportMarketParams{
                query_id: msg.query_id,
                marketplace_fee_address: self.marketplace_fee_address,
                marketplace_fee: self.marketplace_fee,
            }.toCell()
        });
    }

    receive() {}



    // ----- PRIVATE METHODS ----- //
    

    // ---- Getters ---- //

   // Получение адреса Market Item
    get fun get_market_address(item_index: Int): Address {
        return contractAddress(self.get_market_item_state(item_index));
    }

   // Получение StateInit Market Item
    get fun get_market_item_state(item_index: Int): StateInit {
        return initOf MarketItem(myAddress(), item_index);
    }

     // Для получения текущего индекса
    get fun get_current_index(): Int {
        return self.next_item_index;
    }

}



// import "@stdlib/deploy";
// import "./helpers/traits/ownable.tact";
// import "./helpers/messages.tact";

// import "./minter_nft.tact";
// import "./item_nft.tact";
// import "./market_item.tact";

// contract MarketNft with Deployable, Ownable {
//     // Empty init() function is present by default in all Tact contracts
//     // since v1.3.0, so the following may be omitted:
//     //
//     owner: Address;

//     total_sale_item: Int = 0;




//     init() {
//         self.owner = sender();
//     }


//     // last_sale_sender: Address = newAddress(0, 0);

    

//     receive(msg: RequestSaleNftItem) {

//         // Тут мы должны проверить, что это вызывает владелец NFT

//         send(SendParameters{
//             to: msg.nft_address,
//             value: 0,
//             mode: SendRemainingValue,
//             bounce: false,
//             body: GetSaleData{
//                 price: msg.price,
//                 from_address: sender(),
//             }.toCell()
//         });

//         // send(SendParameters{
//         //     to: msg.nft_address,
//         //     value: ton("0.5"),
//         //     bounce: false,
//         //     body: GetSaleData{
//         //         price: msg.price,
//         //         from_address: sender(),
//         //     }.toCell()
//         // });

//         // self.last_sale_sender = sender();
//     }

//     receive(msg: CreateMarketNftItem) {

//         let item_init: StateInit = self.get_market_nft_init_by_index(self.total_sale_item);

//         send(SendParameters{
//             to: contractAddress(item_init),
//             value: 0,
//             mode: SendPayGasSeparately,
//             bounce: false,
//             body: InitMarketItem{
//                 price: 0,
//                 nft_address: sender(),
//             }.toCell(),
//             data: item_init.data,
//             code: item_init.code
//         });
//     }


//     receive(msg: GetInfoForSaleNft) {
//         require(msg.from_address == msg.owner_address, "not owner");
//         require(msg.is_initialized == true, "not initialized");

        
//         dump(msg.is_initialized);
//         dump(msg.index);
//         dump(msg.collection_address);
//         dump(msg.owner_address);
//         dump(msg.price);
//         dump(msg.from_address);
        
//     }


//     // ----- PRIVATE METHODS ----- //

//     // fun createSaleNft(data: CreateSaleNftItem) {
//         // let nft_init: StateInit = initOf ItemNft(myAddress(), data.item_index);
//         // send(SendParameters{
//         //     to: contractAddress(nft_init),
//         //     value: 0
//         // })
//         // send(SendParameters{
//         //     to: data.minter_address,
//         //     value: 0,
//         //     mode:  SendPayGasSeparately, 
//         //     bounce: false
//         // });
//     // }

//     // ---- Getters ---- //

//     // Получение StateInit NFT по индексу
//     get fun get_market_nft_init_by_index(item_index: Int): StateInit {
//         return initOf MarketItem(myAddress(), item_index);
//     }

//     // Получение адреса NFT по индексу
//     get fun get_market_nft_address_by_index(item_index: Int): Address {
//         return contractAddress(self.get_market_nft_init_by_index(item_index));
//     }

// }
