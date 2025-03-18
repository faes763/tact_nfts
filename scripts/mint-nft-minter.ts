import { address, beginCell, toNano } from '@ton/core';
import { MinterNft } from '../wrappers/MinterNft';
import { NetworkProvider } from '@ton/blueprint';
import { config_test } from '../config';
import { ItemNft } from '../wrappers/ItemNft';
import { SaleNft } from '../wrappers/SaleNft';

export async function run(provider: NetworkProvider) {
    const test = provider.open(await SaleNft.fromAddress(address("EQBSasOxoQ6qg0_eeNkjlvyg6hAvZb2boF4y_Wd3eOhnEgDU")))
    // console.log(await test.getGetFixPriceData());

    await test.send(provider.sender(),
{value: toNano("0.45")},
    "Bought on getgems.io");

    // const minterNft = provider.open(await MinterNft.fromAddress(address("EQDon1-SkGFJpxt97npRVaONp_84vlVCUyjeKkBo7uSbVFua")));

    // await minterNft.send(provider.sender(),{ value: toNano("0.1") }, null);

    // await minterNft.send(provider.sender(), { value: toNano("0.1") }, "Mint");
    // const itemNft = provider.open(await ItemNft.fromInit(minterNft.address, 0n));

    // await itemNft.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.05'),
    //     },
    //     {
    //         $$type: 'Deploy',
    //         queryId: 0n,
    //     }
    // );

    // await provider.waitForDeploy(itemNft.address);

    // console.log(await minterNft.getCurrentIndex());
    // console.log(await minterNft.getGetNftAddressByIndex(0n));
    // console.log(await minterNft.getGetNftAddressByIndex(1n));

    

    // await minterNft.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.25'),
    //     },
    //     null
    // );

    // // console.log(beginCell().storeStringTail("b5ee9c720101010100450000860168747470733a2f2f732e67657467656d732e696f2f6e66742f732f363764342f3637643433616539323062356235383762346461326230322f6d6574612e6a736f6e").endCell().toString());
    // await minterNft.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.25'),
    //     },
    //     "Mint"
    // );

    // await provider.waitForDeploy(minterNft.address);

    // run methods on `minterNft`
}
