import { address, beginCell, toNano } from '@ton/core';
import { ItemNft } from '../wrappers/ItemNft';
import { NetworkProvider } from '@ton/blueprint';
import { MinterNft } from '../wrappers/MinterNft';
import { config_test } from '../config';
import { MarketNft } from '../wrappers/MarketNft';
import { MarketItem } from '../wrappers/MarketItem';
import { SaleNft } from '../wrappers/SaleNft';

export async function run(provider: NetworkProvider) {
    const minter = provider.open(await MinterNft.fromInit(
        config_test.mint_data, 
        toNano("0.05"),
        11n,
        1000n,
        address("0QAdD7TxUylbXElqj98f5GuLlmtyIq8NiqnirxlYlvvf3a2L"),
    ));

    const sender = provider.sender();

    await minter.send(
        sender,
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: BigInt(Date.now() - 37),
        }
    );

    await provider.waitForDeploy(minter.address);

    const market = provider.open(await MarketNft.fromInit(0n, null));
    
    await market.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: BigInt(Date.now()),
        }
    );

    await provider.waitForDeploy(market.address);


    // await minter.send(provider.sender(), { value: toNano("0.1") }, "Mint");

    console.log(await ItemNft.fromInit(minter.address, 0n));

    const nft = provider.open(await ItemNft.fromInit(minter.address, 0n));

    console.log(await nft.getGetOwner());

    // let payloadCell = beginCell()
    //     .storeCoins(1000000000)
    //     .endCell()
    // .asSlice();

    // const res = await nft.send(
    //     sender,
    //     {
    //         value: toNano("0.7")
    //     },
    //     {
    //         $$type: "Transfer",
    //         query_id: 37n,
    //         new_owner: market.address,
    //         response_destination: market.address,
    //         custom_payload: null,
    //         forward_amount: toNano("0.5"), // Нужно ~ для оповещения ton("0.04")
    //         forward_payload: payloadCell
    //     }
    // );

    // console.log(res);

    // const item = provider.open(await MarketItem.fromAddress(await market.getGetMarketAddress(0n)));
    
    // const sale = provider.open(await SaleNft.fromAddress(await item.getGetNftSaleAddress()));

    // console.log(`sale address - `, sale.address);

    // console.log(`sale nft_owner_address -`, (await sale.getGetFixPriceData()).nft_owner_address);

    // console.log(await nft.getGetOwner());
    // run methods on `itemNft`
}
