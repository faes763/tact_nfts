import { toNano } from '@ton/core';
import { MarketItem } from '../wrappers/MarketItem';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const marketItem = provider.open(await MarketItem.fromInit());

    await marketItem.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(marketItem.address);

    // run methods on `marketItem`
}
