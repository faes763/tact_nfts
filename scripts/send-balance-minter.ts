import { address, toNano } from '@ton/core';
import { MinterNft } from '../wrappers/MinterNft';
import { NetworkProvider } from '@ton/blueprint';
import { config_test } from '../config';

export async function run(provider: NetworkProvider) {
    const minterNft = provider.open(await MinterNft.fromAddress(address("kQDa16vEoMb5TB5suLW3FuKXnnEF5EPz6pNzKF3ryPpjv2yM")));

    await minterNft.send(
        provider.sender(),
        {
            value: toNano('0.25'),
        },
        null
    );

    await provider.waitForDeploy(minterNft.address);

    // run methods on `minterNft`
}
