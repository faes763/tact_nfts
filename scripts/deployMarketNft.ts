import { toNano } from '@ton/core';
import { MarketNft } from '../wrappers/MarketNft';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const marketNft = provider.open(await MarketNft.fromInit());

    await marketNft.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(marketNft.address);

    // run methods on `marketNft`
}
