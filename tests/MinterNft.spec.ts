import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { Address, beginCell, Dictionary, Slice, toNano } from '@ton/core';
import { MinterNft } from '../wrappers/MinterNft';
import '@ton/test-utils';
import { config_test } from '../config';
import { ItemNft } from '../wrappers/ItemNft';
import { MarketNft } from '../wrappers/MarketNft';
import { MarketItem } from '../wrappers/MarketItem';

describe('MinterNft', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let minterNft: SandboxContract<MinterNft>;
    let marketNft: SandboxContract<MarketNft>;


    let users: SandboxContract<TreasuryContract>[] = []

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        deployer = await blockchain.treasury('deployer');

        minterNft = blockchain.openContract(await MinterNft.fromInit(
            config_test.mint_data, 
            toNano("0.05"),
            11n,
            1000n,
            deployer.address,
        ));

        marketNft = blockchain.openContract(await MarketNft.fromInit(100n, null));



        users.push(await blockchain.treasury('user1'));
        users.push(await blockchain.treasury('user2'));
        users.push(await blockchain.treasury('user3'));

        const deployResult = await minterNft.send(
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
            to: minterNft.address,
            deploy: true,
            success: true,
        });


        



        // Базовый баланс minterNft 1 тон, это нужно для бесплатного минта
        await minterNft.send(deployer.getSender(), {
            value: toNano("1"),
        }, null);

    });

    it.skip('Free mint on sender', async () => {
        await minterNft.send(
            deployer.getSender(),
            {
                value: toNano("1"),
            },
            {
                $$type: "FreeMint",
                to_address: deployer.address
            }
        );

        let balances = Dictionary.empty<bigint, Address>();

        balances.set(0n, users[0].address);
        balances.set(1n, users[1].address);
        balances.set(2n, users[2].address);

        await minterNft.send(
            deployer.getSender(),
            {
                value: toNano("0.05"),
            },
            {
                $$type: "FreeManyMint",
                to_addresses: balances,
                length: 3n
            }
        );

        const lengthNft = await minterNft.getCurrentIndex();

        console.log(lengthNft);

        const addresses = await Promise.all(Array.from({ length: Number(lengthNft) }).map((_, i) => minterNft.getGetNftAddressByIndex(BigInt(i))));
        const nftsContracts = await Promise.all(addresses.map(address => (ItemNft.fromAddress(address))));
        const [nft1, nft2, nft3, nft4] = await Promise.all(nftsContracts.map((contract, i) => blockchain.openContract(contract)));

        expect((await nft1.getGetOwner()).toString()).toBe(deployer.address.toString());
        // expect((await nft2.getGetOwner()).toString()).toBe(users[0].address.toString());
    });

    it.skip("Buy & Transfer NFT", async () => {

        await minterNft.send(
            users[0].getSender(),
            {
                value: toNano("1"),
            },
            "Mint"
        );

        const lengthNft = await minterNft.getCurrentIndex();

        console.log(lengthNft);

        const addresses = await Promise.all(Array.from({ length: Number(lengthNft) }).map((_, i) => minterNft.getGetNftAddressByIndex(BigInt(i))));
        const nftsContracts = await Promise.all(addresses.map(address => (ItemNft.fromAddress(address))));
        const [nft1, nft2, nft3, nft4] = await Promise.all(nftsContracts.map((contract, i) => blockchain.openContract(contract)));

        const oldOwner = await nft1.getGetOwner();

        const to_transfer = users[1].address;


        await nft1.send(users[0].getSender(), {
            value: toNano("0.15"),
        }, { 
            $$type: "Transfer",
            query_id: 1n,
            new_owner: to_transfer,
            response_destination: deployer.address,
            custom_payload: null,
            forward_amount: toNano('0.01'),
            forward_payload: beginCell().storeUint(1, 32).endCell().asSlice()
        });

        const newOwner = await nft1.getGetOwner();

        expect(newOwner.toString()).toBe(to_transfer.toString());
        expect(oldOwner.toString()).not.toBe(newOwner.toString());
    });

    it("Buy & Sale", async () => {
        await minterNft.send(
            users[0].getSender(),
            {
                value: toNano("1"),
            },
            "Mint"
        );

        const lengthNft = await minterNft.getCurrentIndex();

        const addresses = await Promise.all(Array.from({ length: Number(lengthNft) }).map((_, i) => minterNft.getGetNftAddressByIndex(BigInt(i))));
        const nftsContracts = await Promise.all(addresses.map(address => (ItemNft.fromAddress(address))));
        const [nft1] = await Promise.all(nftsContracts.map((contract, i) => blockchain.openContract(contract)));

        await marketNft.send(
            users[0].getSender(),
            {
                value: toNano("0.5"),
            },
            {
                $$type: "CreateMarketNftItem",
                nft_address: nft1.address,
                full_price: toNano("1")
            }
        );


        const sale_address = await marketNft.getGetMarketAddress(nft1.address, toNano("1"));
        

        const sale = await blockchain.openContract(await MarketItem.fromAddress(sale_address));

        await sale.send(users[0].getSender(),{value: toNano("0.1")}, {$$type: "Deploy", queryId: BigInt(Date.now())});

        console.log(await sale.getMyBalance());

        await nft1.send(
            users[0].getSender(),
            {
                value: toNano("0.1")
            }, 
            {
                $$type: "Transfer",
                query_id: 37n,
                new_owner: sale_address,
                response_destination: sale_address,
                custom_payload: null,
                forward_amount: toNano("0.04"), // Нужно ~ для оповещения ton("0.04")
                forward_payload: beginCell().storeUint(1, 32).endCell().asSlice()
            }
        );


        let sale_data = await sale.getGetFixPriceData();

        // Если nft_owner_address = sale_address, то перевод был сделан успешно
        await expect(sale_data.nft_owner_address.toString()).toBe(sale_address.toString());

        

        const res = await sale.send(
            deployer.getSender(),
            {
                value: sale_data.full_price + toNano("0.5")
            },
            null
        );

        console.log(res.events);
        console.log(await sale.getMyBalance());

        sale_data = await sale.getGetFixPriceData();
        console.log(sale_data);
        console.log(deployer.address);

    })
});

function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}
