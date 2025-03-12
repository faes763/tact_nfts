import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { MarketItem } from '../wrappers/MarketItem';
import '@ton/test-utils';

describe('MarketItem', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let marketItem: SandboxContract<MarketItem>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        marketItem = blockchain.openContract(await MarketItem.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await marketItem.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: marketItem.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and marketItem are ready to use
    });
});
