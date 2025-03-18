import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/market/sale_nft.tact',
    options: {
        debug: true,
    },
};
