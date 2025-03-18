import { beginCell } from "@ton/core";

const url = "https://s.getgems.io/nft/b/c/62655b6fcc4f8f71aa82a028/edit/meta-1710397460164.json";

const config_test = {
    mint_data: beginCell().storeUint(1, 8).storeStringTail(url).endCell(),
}


export { config_test }