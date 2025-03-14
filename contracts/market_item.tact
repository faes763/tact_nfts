import "@stdlib/deploy";
import "./helpers/traits/ownable.tact";
import "./helpers/messages.tact";

// Ориентировался на https://github.com/getgems-io/nft-contracts/blob/main/packages/contracts/nft-fixprice-sale-v3/description-ru.md


// Этот контракт используется когда продавец хочет продать нфт за фиксированную цену в тонах. 
// Продавец деплоит контракт продажи и передает нфт на этот контракт. 
// Покупатель отправляет на контракт продажи тоны + ~0.1 для оплаты газа. 
// Контракт передает нфт покупателю, а тоны продавцу, после этого покупка считается совершенной. 
// Продавец может отменить продажу в любой момент до покупки.

// Перед покупкой необходимо убедиться что нфт достаточно 0.1 тон для смены владельца, если этого недостаточно то надо прислать больше тонов. 
// Если нет возможности рассчитать сумму заранее, то для совершения покупки рекомендуется прислать full_price + 1 тон.

// ~ необходимо для метода Transfer
const nft_transfer_value: Int = ton("0.1");



// Для деления на 100%
const hundred_percent: Int = 100000000000;

// Для вычесления процентов
@name(muldiv)
native mulDiv(a: Int, b: Int, c: Int): Int;

contract MarketItem {

    is_complete: Bool = false; // завершена ли продажа или нет
    created_at: Int; // время создания контракта, используется чтобы одинаковые контракты имели разные адреса
    marketplace_address: Address;
    nft_address: Address;
    nft_owner_address: Address;
    full_price: Int as coins;
    marketplace_fee_address: Address; // адрес для комиссии маркетплейса
    marketplace_fee: Int; // Размер комиссии маркетплейса
    royalty_address: Address; // адрес для роялти коллекции
    sold_at: Int = 0; // Дата продажи нфт, если она состоялась
    query_id: Int = 0; // query_id который привёл к продаже nft

    owner: Address;


    nft_collection_address: Address; // Адрес nft коллекции 


    numerator: Int;
    denominator: Int;


    init(marketplace_address: Address, nft_address: Address, full_price: Int, marketplace_fee_address: Address?, marketplace_fee: Int) {
        self.created_at = now();
        self.marketplace_address = marketplace_address;
        self.nft_address = nft_address;
        self.full_price = full_price + nft_transfer_value;
        self.marketplace_fee = marketplace_fee;

        // поля nft_owner_address, nft_address, marketplace_fee_address, royalty_address должны быть заполнены и содержать валидные адреса MsgAddress workchain 0
        
        self.royalty_address = newAddress(0, 0);
        self.numerator = 0;
        self.denominator = 1;

        self.marketplace_fee_address = newAddress(0, 0);
        if(marketplace_fee_address != null) {
            self.marketplace_fee_address = marketplace_fee_address!!;
        }

        self.nft_owner_address = newAddress(0, 0); // У нфт нет owner, до тех пор пока nft не перейдёт во владение контракта

        self.owner = sender();


        self.nft_collection_address = newAddress(0, 0);


        // Отправляю сообщения на nft_address, для получения адреса коллекции
        send(SendParameters{
            to: nft_address,
            value: ton("0.02"),
            bounce: false,
            body: GetStaticData{
                query_id: now(),
            }.toCell()
        });


    }


    // Если контракт получил nft
    receive(msg: OwnershipAssigned) {
        if(sender() != self.nft_address) {
            dump("But");
            // Если nft не то, то возвращаем его
            send(SendParameters{
                to: sender(),
                value: 0,
                mode: SendRemainingValue,
                body: Transfer{
                    query_id: msg.query_id,
                    new_owner: msg.prev_owner,
                    response_destination: msg.prev_owner,
                    custom_payload: "Invalid NFT".asComment(),
                    forward_amount: 0,
                    forward_payload: emptySlice()
                }.toCell()
            });
        } else {
            self.nft_owner_address = myAddress();
            self.is_complete = false;

            self.owner = msg.prev_owner;

            // Оповещаем, прошлого владельца, что нфт получено
            send(SendParameters{
                to: msg.prev_owner,
                value: 0,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: "Nft Received".asComment()
            });
        }
    }

    // Получаю сообщение от nft_address, с информацией о коллекции
    receive(msg: ReportStaticData) {
        if(sender() == self.nft_address) {
            self.nft_collection_address = msg.collection;
            // Отправляю на коллекцию запрос на получение royalty данных
            send(SendParameters{
                to: msg.collection,
                value: ton("0.02"),
                body: GetRoyaltyParams{
                    query_id: now()
                }.toCell()
            });
        }
    }

    // Получаю сообщение от nft_collection_address, с информацией о royalty
    receive(msg: ReportRoyaltyParams) {
        if(sender() == self.nft_collection_address) {
            self.denominator = msg.denominator;
            self.numerator = msg.numerator;
            self.royalty_address = msg.destination;

            // Для предотвращения ошибки при numerator / 0, При некоректном royalty коллекции
            if(self.denominator == 0) {
                self.numerator = 0;
                self.denominator = 1;
            }
        }
    }


    // BUY TON METHOD
    receive() { 
        let ctx: Context = context();
        dump(self.full_price);
        dump(ctx.value);

        require(self.full_price <= ctx.value, "Need more TON");




        if(self.royalty_address != newAddress(0, 0)) {
        dump("send royalty");

            let royalty_fee: Int = mulDiv(self.full_price, mulDiv(self.numerator, hundred_percent, self.denominator), hundred_percent);

            // Отправка роялти на royalty_address
            send(SendParameters{
                to: self.royalty_address,
                value: royalty_fee
            });

            ctx.value = ctx.value - royalty_fee;
        }

        if(self.marketplace_fee_address != newAddress(0, 0)) {
        dump("send marketplace_fee");

            // Отправка комиссии площадке
            send(SendParameters{
                to: self.marketplace_fee_address,
                value: self.marketplace_fee
            });

            ctx.value = ctx.value - self.marketplace_fee;
        }

        dump("transfer nft");

        self.transfer(sender(), "Nft receive".asComment(), emptySlice(), SendIgnoreErrors);


        dump("Test");


        // id запроса который привел к продаже нфт
        self.query_id = now();


        // Переводим все деньги при продаже
        send(SendParameters{
            to: self.marketplace_address,
            value: 0,
            mode: SendRemainingBalance
        });

    }

    receive("Cancel") {
        require(sender() == self.owner, "You not owner");
        require(myAddress() == self.nft_owner_address, "The contract has no nft");
        require(self.is_complete == false, "The sale has already been made or cancelled");

        self.transfer(self.owner, emptyCell(), emptySlice(), SendRemainingValue);
    }



    // В дефолтном методе Deploy вызывается self.reply, который возвращает ton, нам это не надо, поэтому создаём пустой msg, для корректной работы
    receive(msg: Deploy) {}


    // ----- PRIVATE METHODS ----- //

    fun transfer(new_owner: Address, custom_payload: Cell, forward_payload: Slice, mode: Int) {
        send(SendParameters{
            to: self.nft_address,
            value: nft_transfer_value, // ~ ton("0.04")
            mode: mode,
            body: Transfer{
                query_id: now(),
                new_owner: new_owner,
                response_destination: new_owner,
                custom_payload: custom_payload,
                forward_amount: 0,
                forward_payload: forward_payload
            }.toCell()
        });

        self.is_complete = true;
        self.nft_owner_address = new_owner;
    }

    // ----- Getters ----- //

    get fun get_fix_price_data(): MarketData {
        return MarketData{
            is_complete: self.is_complete,
            created_at: self.created_at,
            marketplace_address: self.marketplace_address,
            nft_address: self.nft_address,
            nft_owner_address: self.nft_owner_address,
            full_price: self.full_price,
            marketplace_fee_address: self.marketplace_fee_address,
            marketplace_fee: self.marketplace_fee,
            royalty_address: self.royalty_address,
            royalty_amount: mulDiv(self.numerator, self.denominator, hundred_percent),
            sold_at: self.sold_at,
            query_id: self.query_id,
        }
    }

    get fun myBalance(): Int {
        return myBalance();
    }
}




// import "@stdlib/deploy";
// import "./helpers/traits/ownable.tact";
// import "./helpers/messages.tact";

// contract MarketItem with Deployable, Ownable {

//     market_address: Address;
//     item_index: Int;

//     owner: Address;

//     nft_address: Address;

//     init(market_address: Address, item_index: Int) {
//         self.market_address = market_address;
//         self.item_index = item_index;
//         self.owner = market_address;
//         self.nft_address = newAddress(0, 0);
//     }


//     receive(msg: InitMarketItem) {
//         require(sender() == self.market_address, "not from market");

//         self.nft_address = msg.nft_address;  

//         send(SendParameters{
//             to: self.nft_address,
//             value: 0,
//             mode: SendRemainingValue,
//             bounce: false,
//             body: "owner".asComment()
//         });
//     }

//     receive(msg: SetOwner) {
//         require(sender() == self.nft_address, "not from nft");
//         self.owner = msg.owner_address;

//     }

// }
