# A tester for Defi interactions on EVMs

This repo is using foundry and currently supports following DEXs:

* Uniswap V2

* Uniswap V3

---

### How to use

Be sure to load repo's submodules. The DEX codes have been changed to be able to deploy on local foundry testnets.  
Also, add files in the directory `./libChanges` to the foundry project. They contain necessary fixes for the submodules to work in the foundry environment (anvil).  

---

### Points about deployments of each DEX code:

* **General**: Added minimal interfaces for tests in the `.test/interfaces` directory. Therefore avoiding version and dependancies errors.

* Uniswap v2: Change core files with the one provided in `libChanges/v2-periphry`

* Uniswap V3: In the v3-perphery, change all openzeppline imports to an older version of openzeppline, to be able to deploy on local foundry testnets. Version 3.4.2 works well. Its easier if you download oz using `forge install openzipplin_3.4.2_uniswapV3=OpenZeppelin/openzeppelin-contracts@v3.4.2` and then add `"@uniV3_OZ/=lib/openzipplin_3.4.2_uniswapV3/"` to the remappings. Then replace all references of `openzeppline/` with `@uniV3_OZ/` in the v3-periphery.  
Also if faced with `Stack too deep` error, add the following to foundry config.toml: 
    ```
        [profile.default]
        optimizer = true
        optimizer_runs = 200
    ```

* Sushiswap V2: First download the main repo from github. Be sure to download the module to the directory `lib/sushiswap-v2-core`. Use the command below:  

    ```bash
        git clone https://github.com/sushiswap/v2-core lib/sushiswap-v2-core
    ```  
    Also, change core files with the one provided in `libChanges/v2-periphry`.


* Sushiswap V3: First download the main repo from github. Be sure to download the module to the directory `lib/sushiswap-v3-core`. Use the commands below:  

    ```bash
        git clone https://github.com/sushiswap/v3-core lib/sushiswap-v3-core
        git clone https://github.com/sushiswap/v3-periphery lib/sushiswap-v3-periphery
    ```  

* Camelot V2: First download the main repo from github. Be sure to download the module to the directory `lib/camelot-v2-core` and `lib/camelot-v2-periphery`. Use the commands below:

    ```bash
        git clone https://github.com/CamelotLabs/core lib/camelot-v2-core
        git clone https://github.com/CamelotLabs/periphery lib/camelot-v2-periphery
    ```  
    Add `"camelot-ammv2-core/=lib/camelot-v2-core/"` to the remappings, and also replace the file present at libChanges with that of the downloaded repos.


* Camelot V3: Uses algebrav1.9, so download it with command below:
    ```bash
        git clone https://github.com/cryptoalgebra/AlgebraV1.9 lib/camelot-v3
    ```

## Addresses used

*All addresses are in ETH mainnet, except specified otherwise.*  

* WETH: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

* USDT: 0xdAC17F958D2ee523a2206206994597C13D831ec7

* Uniswap V2 Factory: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f

* Uniswap V2 Router02: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

* Uniswap V3 Factory: 0x1F98431c8aD98523631AE4a59f267346ea31F984

* Uniswap V3 SwapRouter02: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45

* Uniswap V3 NFTDescriptor: 0x42B24A95702b9986e82d421cC3568932790A48Ec

* Uniswap V3 NonfungiblePositionManager: 0xC36442b4a4522E871399CD717aBDD847Ab11FE88

* Uniswap V3 NonfungibleTokenPositionDescriptor: 0x91ae842A5Ffd8d12023116943e72A606179294f3

* Sushiswap V2 Factory: 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac

* Sushiswap V2 Router02: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F

* Sushiswap V3 Factory: 0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F

* Sushiswap V3 Position Manager: 0x2214A42d8e2A1d20635c2cb0664422c528B6A432

* Sushiswap V3 Nonfungible Token Position Descriptor: 0x1C4369df5732ccF317fef479B26A56e176B18ABb

* Sushiswap V3 SwapRouter: 0x2E6cd2d30aa43f40aa81619ff4b6E0a41479B13F

* Sushiswap V3 NFT Descriptor: 0x67468E6c4418d58B1b41bc0A795BaCB824F70792

* Camelot V2 Factory: 0x6EcCab422D763aC031210895C81787E87B43A652 *(Arbitrum)*

* Camelot V2 Router: 0xc873fEcbd354f5A56E00E710B90EF4201db2448d *(Arbitrum)*

* Camelot V3 Algebra Factory: 0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B *(Arbitrum)*

* Camelot V3 Nonfungible Token Position Manager: 0x00c7f3082833e796A5b3e4Bd59f6642FF44DCD15 *(Arbitrum)*

* Camelot V3 SwapRouter: 0x1F721E2E82F6676FCE4eA07A5958cF098D339e18 *(Arbitrum)*

* Camelot V3 Algebra Interface Multicall: AlgebraInterfaceMulticall *(Arbitrum)*
