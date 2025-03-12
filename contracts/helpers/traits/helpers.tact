import "./ownable.tact";


const minTonsForStorage: Int = ton("0.005");
const gasConsumption: Int = ton("0.005");

trait Helpers with Ownable {

    owner: Address;


    fun msgValue(): Int {
        let ctx: Context = context();
        let value: Int = ctx.value;
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = minTonsForStorage - min(tonBalanceBeforeMsg, minTonsForStorage);
        value = value - (storageFee + gasConsumption);

        return value;
    }


    receive("Withdraw Safe") {
        self.onlyOwner();

        let amount: Int = myBalance() - context().value - minTonsForStorage;

        send(SendParameters{
            to: sender(),
            value: amount,
            mode: SendRemainingValue + SendIgnoreErrors,
            bounce: true,
        });
    }

    get fun myBalance(): Int {
        return myBalance();
    }



}