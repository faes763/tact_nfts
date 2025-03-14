import "@stdlib/deploy";
import "./helpers/traits/ownable.tact";
import "./helpers/messages.tact";

import "./minter_nft.tact";
import "./item_nft.tact";
import "./market_item.tact";

contract MarketNft with Deployable, Ownable {

    owner: Address;

    marketplace_fee_address: Address?; 
    marketplace_fee: Int;

    init(marketplace_fee: Int, marketplace_fee_address: Address?) {
        self.owner = sender();

        self.marketplace_fee = marketplace_fee;

        self.marketplace_fee_address = marketplace_fee_address;
    }


    receive(msg: CreateMarketNftItem) {

        let market_item_init: StateInit = self.get_market_item_state(msg.nft_address, msg.full_price);

        send(SendParameters{
            to: contractAddress(market_item_init),
            value: 0,
            mode: SendRemainingValue,
            code: market_item_init.code,
            data: market_item_init.data,
        });
    }

    // ----- PRIVATE METHODS ----- //
    

    // ---- Getters ---- //

   // Получение адреса Market Item
    get fun get_market_address(nft_address: Address, full_price: Int,): Address {
        return contractAddress(self.get_market_item_state(nft_address, full_price));
    }

   // Получение StateInit Market Item
    get fun get_market_item_state(nft_address: Address, full_price: Int,): StateInit {
        return initOf MarketItem(myAddress(), nft_address, full_price, self.marketplace_fee_address, self.marketplace_fee);
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
