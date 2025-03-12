import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/minter_nft.tact',
    options: {
        debug: true,
    },
};
