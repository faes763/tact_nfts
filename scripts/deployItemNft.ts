import { toNano } from '@ton/core';
import { ItemNft } from '../wrappers/ItemNft';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const itemNft = provider.open(await ItemNft.fromInit());

    await itemNft.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(itemNft.address);

    // run methods on `itemNft`
}
