import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/market/market_nft.tact',
    options: {
        debug: true,
    },
};
