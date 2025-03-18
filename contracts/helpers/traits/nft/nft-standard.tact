import "../../messages.tact";
import "../ownable.tact";
import "../helpers.tact";

trait NftItemStandard with Ownable, Helpers {

    collection_address: Address;

    item_index: Int;

    individual_content: Cell?;

    owner: Address;

    is_initialized: Bool;

    // Standard method
    receive(msg: Transfer) {
        let ctx: Context = context();

        if(self.is_initialized == false) {
            // Проверяем, что метод вызывается collection_address, если контракт не инициализирован
            self.isCollection(null);
            self.is_initialized = true;

            // Передаем владение
            self.transfer(msg);
            self.individual_content = msg.custom_payload;

        } else {
            self.onlyOwner();

            // Передаем владение
            self.transfer(msg);
        }
    }

    // Standard method
    receive(msg: GetStaticData){ 
        let ctx: Context = context();
        
        send(SendParameters {
            to: ctx.sender,
            value: 0,
            mode: SendRemainingValue,  // (return msg amount except gas fees) 
            bounce: true,
            body: ReportStaticData{
                query_id: msg.query_id,
                index_id: self.item_index,
                collection: self.collection_address
            }.toCell()
        });
    }

    // ----- PRIVATE METHODS ----- //

    fun transfer(data: Transfer) {

        self.owner = data.new_owner;

        // Количество ton coin которые будут отправлены новому владельцу
        if (data.forward_amount > 0) {
            send(SendParameters{
                to: data.new_owner,
                value: data.forward_amount,
                mode:  SendPayGasSeparately, 
                bounce: true,
                body: OwnershipAssigned{
                    query_id: data.query_id,
                    prev_owner: sender(),
                    forward_payload: data.forward_payload,
                }.toCell()
            }); 
        }

        let msgValue: Int = self.msgValue() - context().readForwardFee();

        // Оповещаем о том response_destination, что владелец изменился, отправляя излишки ton coin, исключая forward_amount
        if(data.response_destination != null) {
            send(SendParameters{
                to: data.response_destination!!,
                value: msgValue - data.forward_amount,
                bounce: true,
                body: Excesses { query_id: data.query_id }.toCell(),
                mode: SendPayGasSeparately
            });
        }
    }


    fun isCollection(collection_address: Address?) {
        if(collection_address != null) {
            require(collection_address == self.collection_address, "Only collection method");
        } else {
            require(sender() == self.collection_address, "Only collection method");
        }
    }

    override fun _transferOwnerShip(new_owner: Address) {
        require(false, "not implemented");
    }

    // ---- Getters ---- //

    get fun get_nft_data(): GetNftData {


        return GetNftData{
            is_initialized: self.is_initialized, 
            index: self.item_index, 
            collection_address: self.collection_address, 
            owner_address: self.owner,
            individual_content: self.individual_content!!
        };
    }
}

// https://github.com/ton-blockchain/TEPs/blob/master/text/0066-nft-royalty-standard.md
trait NftRoyalty {

    numerator: Int;
    denominator: Int;
    destination: Address;


    receive(msg: GetRoyaltyParams) {
        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue,
            body: ReportRoyaltyParams{
                numerator: self.numerator,
                denominator: self.denominator,
                destination: self.destination,
                query_id: msg.query_id,
            }.toCell()
        });
    }

    get fun get_royalty_params(): RoyaltyParams {
        return RoyaltyParams{
            numerator: self.numerator,
            denominator: self.denominator,
            destination: self.destination,
        }
    }
}