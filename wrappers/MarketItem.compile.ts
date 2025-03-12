import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/market_item.tact',
    options: {
        debug: true,
    },
};
