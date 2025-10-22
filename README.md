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

* Uniswap v2: Change core files with the one provided in `libChanges/v2-periphry`

* Uniswap V3: In the v3-perphery, change all openzeppline imports to an older version of openzeppline, to be able to deploy on local foundry testnets. Version 3.4.2 works well. Its easier if you download oz using `forge install openzipplin_3.4.2_uniswapV3=OpenZeppelin/openzeppelin-contracts@v3.4.2` and then add `"@uniV3_OZ/=lib/openzipplin_3.4.2_uniswapV3/"` to the remappings. Then replace all references of `openzeppline/` with `@uniV3_OZ/` in the v3-periphery.  
Also if faced with `Stack too deep` error, add the following to foundry config.toml: 
    ```
        [profile.default]
        optimizer = true
        optimizer_runs = 200
    ```

* **General**: Added minimal interfaces for tests in the `.test/interfaces` directory. Therefore avoiding version and dependancies errors.

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