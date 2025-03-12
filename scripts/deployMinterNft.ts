import { toNano } from '@ton/core';
import { MinterNft } from '../wrappers/MinterNft';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const minterNft = provider.open(await MinterNft.fromInit());

    await minterNft.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(minterNft.address);

    // run methods on `minterNft`
}
