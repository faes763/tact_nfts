import "@stdlib/deploy";
import "./helpers/traits/ownable.tact";
import "./helpers/messages.tact";

contract MarketItem with Deployable, Ownable {

    market_address: Address;
    item_index: Int;

    owner: Address;

    nft_address: Address;

    init(market_address: Address, item_index: Int) {
        self.market_address = market_address;
        self.item_index = item_index;
        self.owner = market_address;
        self.nft_address = newAddress(0, 0);
    }


    receive(msg: InitMarketItem) {
        require(sender() == self.market_address, "not from market");

        self.nft_address = msg.nft_address;  

        send(SendParameters{
            to: self.nft_address,
            value: 0,
            mode: SendRemainingValue,
            bounce: false,
            body: "owner".asComment()
        });
    }

    receive(msg: SetOwner) {
        require(sender() == self.nft_address, "not from nft");
        self.owner = msg.owner_address;

    }

}
