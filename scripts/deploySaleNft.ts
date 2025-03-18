import { toNano } from '@ton/core';
import { SaleNft } from '../wrappers/SaleNft';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const saleNft = provider.open(await SaleNft.fromInit());

    await saleNft.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(saleNft.address);

    // run methods on `saleNft`
}
