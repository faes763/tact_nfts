import { address, toNano } from '@ton/core';
import { MinterNft } from '../wrappers/MinterNft';
import { NetworkProvider } from '@ton/blueprint';
import { config_test } from '../config';

export async function run(provider: NetworkProvider) {
    const minterNft = provider.open(await MinterNft.fromInit(
        config_test.mint_data, 
        toNano("0.01"),
        11n,
        1000n,
        address("0QAdD7TxUylbXElqj98f5GuLlmtyIq8NiqnirxlYlvvf3a2L")
    ));

    await minterNft.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: BigInt(Date.now()),
        }
    );

    await provider.waitForDeploy(minterNft.address);

    // run methods on `minterNft`
}
