



// ----- MINTER NFT MESSAGES ----- //

// Для бесплатного минта работает по whitelist
message FreeMint {
    to_address: Address?;
}
// Для бесплатного минта по ряду адресов работает по whitelist
message FreeManyMint {
    to_addresses: map<Int, Address>; // Массив адресов
    length: Int; // Длина массива
}

message ChangePrice {
    new_price: Int;
}

// Структура для получения информации о коллекции
struct CollectionData {
    next_item_index: Int;
    collection_content: Cell;
    owner_address: Address;
}




// ----- ITEM NFT MESSAGES ----- //

// Для перевода NFT
message(0x5fcc3d14) Transfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address?;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}


struct RoyaltyParams {
    numerator: Int;
    denominator: Int;
    destination: Address;
}

message(0xa8cb00ad) ReportRoyaltyParams {
    numerator: Int; 
    denominator: Int; 
    destination: Address;
    query_id: Int as uint64;
}

message(0x693d3950) GetRoyaltyParams {
    query_id: Int as uint64;
}

// Для оповещения о переводе NFT
message(0xd53276db) Excesses {
    query_id: Int as uint64;
}

// Для оповещения о переводе NFT
message(0x05138d91) OwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

// Структура для получения информации о NFT
struct GetNftData {
    is_initialized: Bool;
    index: Int;
    collection_address: Address;
    owner_address: Address;
    individual_content: Cell;
}
// Для получения информации о NFT на адрес вызывающего
message(0x2fcb26a2) GetStaticData {
    query_id: Int as uint64;
}

// Структура для отправки информации о NFT на адрес вызывающего
message(0x8b771735) ReportStaticData {
    query_id: Int as uint64;
    index_id: Int;
    collection: Address;
}

// Для получения полной информации о NFT для выставления на продажу
message GetSaleData {
    price: Int as coins;
    from_address: Address;
}


// ----- MARKET NFT MESSAGES ----- //

// Нужно для создания
message CreateMarketNftItem {
    nft_address: Address; 
    full_price: Int; 
}


// ----- MARKET ITEM NFT MESSAGES ----- //

struct MarketData {
    is_complete: Bool = false; // завершена ли продажа или нет
    created_at: Int; // время создания контракта, используется чтобы одинаковые контракты имели разные адреса
    marketplace_address: Address;
    nft_address: Address;
    nft_owner_address: Address;
    full_price: Int as coins;
    marketplace_fee_address: Address; // адрес для комиссии маркетплейса
    marketplace_fee: Int; // Размер комиссии маркетплейса
    royalty_amount: Int; // размер роялти коллекции
    royalty_address: Address; // адрес для роялти коллекции
    sold_at: Int = 0; // Дата продажи нфт, если она состоялась
    query_id: Int = 0; // query_id который привёл к продаже nft
}