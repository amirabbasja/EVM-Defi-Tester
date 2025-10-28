// SPDX-License_Identifier: MIT
pragma solidity >=0.8.5;

// Interfaces
import {IWETH9} from "./interfaces/IWETH9.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {ISwapRouter02} from "./interfaces/ISwapRouter02.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {ICamelotRouter} from "./interfaces/ICamelotRouter.sol";
import {ISwapRouterCamelotV3} from "./interfaces/ISwapRouterCamelotV3.sol";

contract AtomicArbitrage {
    /**
     * ERR0: Only owner can call this function
     * ERR1: Only supports pairs that have WETH as one of the tokens
     * ERR2: Exchange not supported
     */
    address private immutable i_owner;

    IWETH9 private immutable i_WETH9;
    IUniswapV2Router02 private immutable i_uniswapV2Router02;
    ISwapRouter02 private immutable i_uniswapV3Router;
    IUniswapV2Router02 private immutable i_sushiswapV2Router02;
    ISwapRouter private immutable i_sushiswapV3Router;
    ICamelotRouter private immutable i_camelotRouter;
    ISwapRouterCamelotV3 private immutable i_camelotV3Router;


    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        address recipient;
        uint256 deadline;
        bytes extra; // exchange-specific config (e.g., path, fee, sqrtPriceLimitX96, minOut)
    }

    /**
     * @dev Modifier to allow only the owner to call certain functions
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Helper function for onlyOwner modifier, reduces gas costs by using internal function
     */
    function _onlyOwner() internal view {
        require(msg.sender == i_owner, "ERR0");
    }

    constructor(
        address WETH9Address,
        address idx0_address, // UniswapV2Router02 address
        address idx1_address, // UniswapV3SwapRouter address
        address idx2_address, // SushiswapV2Router02 address
        address idx3_address, // SushiswapV3SwapRouter address
        address idx4_address, // CamelotV2Router address
        address idx5_address // CamelotV3SwapRouter address
    ) {
        i_owner = msg.sender;
        i_WETH9 = IWETH9(WETH9Address);
        i_uniswapV2Router02 = IUniswapV2Router02(idx0_address);
        i_uniswapV3Router = ISwapRouter02(idx1_address);
        i_sushiswapV2Router02 = IUniswapV2Router02(idx2_address);
        i_sushiswapV3Router = ISwapRouter(idx3_address);
        i_camelotRouter = ICamelotRouter(idx4_address);
        i_camelotV3Router = ISwapRouterCamelotV3(idx5_address);
    }

    /**
     * The contract which makes the atomic swaps, executng an arbitrage between two exchanges. 
     * Currently supports pairs that have WETH as one of the tokens. The goal is to increase the primary token balance.
     * 
     * @dev TODO: Add support for other primary tokens
     * @param idx1 - The index of the first exchange
     * @param idx2 - The index of second exchange
     * @param amountIn - The amount to swap of the primary token
     * @param firstPool - The address of the first pool (Must have the higher price for primary token, because we start by selling the primary token to a higher price and buy it cheaper)
     * @param secondPool - The address of the second pool
     * @param primaryTokenAddress - The address of the primary token (The token which we are tying to increase its amount in wallet)
     * @param mediumTokenAddress - The address of the medium token (e.g., USDT, if primary token is WETH and we are arbitraging in WETH/USDT pools)
     */
    function makeArb(
        uint idx1,
        uint idx2,
        uint256 amountIn,
        address firstPool,
        address secondPool,
        address primaryTokenAddress,
        address mediumTokenAddress
    ) external onlyOwner {
        // Currently supports pairs that have WETH as one of the tokens. The goal is to increase the primary token balance.
        if (primaryTokenAddress != address(i_WETH9)) {
            revert("ERR1"); // TODO: Add support for other primary tokens
        }

        // 1. Weap ETH to WETH
        _wrapETH(amountIn);

        // 2. Sell WETH for the medium token in the first pool
        SwapParams memory p1 = SwapParams({
            tokenIn: primaryTokenAddress,
            tokenOut: mediumTokenAddress,
            amountIn: amountIn,
            recipient: address(this),
            deadline: block.timestamp + 300,
            extra: abi.encode()
        });
        _makeSwap(idx1,p1);

        // 3. Sell the medium token for WETH in the second pool
        // 4. Unwrap WETH to ETH
    }

    /**
     * Wraps ether to WETH
     * @param amount - The amount to wrap
     */
    function _wrapETH(uint256 amount) public payable onlyOwner {
        i_WETH9.deposit{value: amount}();
    }


    /**
     * Unwraps WETH to ether
     * @param amount - The amount to wrap
     */
    function _unwrapETH(uint256 amount) public onlyOwner {
        i_WETH9.withdraw(amount);
        (bool success, ) = payable(i_owner).call{value: amount}("");
        require(success, "ERR3");
    }

    /**
     * The function that makes a single swap on a given exchange
     * @param idx - The index of the exchange the we are making the swap on
     * @param p - The swap parameters. It is a struct with type SwapParams
     */
    function _makeSwap(uint idx, SwapParams memory p) public {
        if        (idx == 0) {
            _swapUniswapV2(p);
        } else if (idx == 1) {
            _swapUniswapV3(p);
        } else if (idx == 2) {
            _swapSushiswapV2(p);
        } else if (idx == 3) {
            _swapSushiswapV3(p);
        } else if (idx == 4) {
            _swapCamelotV2(p);
        } else if (idx == 5) {
            _swapCamelotV3(p);
        } else {
            revert("ERR2");
        }
    }

    function _swapUniswapV2(SwapParams memory p) public {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_uniswapV2Router02), p.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = p.tokenIn;
        path[1] = p.tokenOut;
        
        i_uniswapV2Router02.swapExactTokensForTokens(
            p.amountIn,
            0,
            path,
            p.recipient,
            p.deadline
        );
    }

    function _swapUniswapV3(SwapParams memory p) public {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_uniswapV3Router), p.amountIn);

        (uint24 fee, uint160 sqrtPriceLimitX96, uint256 amountOutMinimum) = abi.decode(p.extra, (uint24, uint160, uint256));

        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02.ExactInputSingleParams({
            tokenIn: p.tokenIn,
            tokenOut: p.tokenOut,
            fee: fee,
            recipient: p.recipient,
            amountIn: p.amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        i_uniswapV3Router.exactInputSingle(params);
    }

    function _swapSushiswapV2(SwapParams memory p) public {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_sushiswapV2Router02), p.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = p.tokenIn;
        path[1] = p.tokenOut;
        
        i_sushiswapV2Router02.swapExactTokensForTokens(
            p.amountIn,
            0,
            path,
            p.recipient,
            p.deadline
        );
    }

    function _swapSushiswapV3(SwapParams memory p) public {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_sushiswapV3Router), p.amountIn);

        (uint24 fee, uint160 sqrtPriceLimitX96, uint256 amountOutMinimum) = abi.decode(p.extra, (uint24, uint160, uint256));

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: p.tokenIn,
            tokenOut: p.tokenOut,
            fee: fee,
            recipient: p.recipient,
            amountIn: p.amountIn,
            deadline: p.deadline,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        i_sushiswapV3Router.exactInputSingle(params);
    }

    function _swapCamelotV2(SwapParams memory p) public {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_camelotRouter), p.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = p.tokenIn;
        path[1] = p.tokenOut;
        
        i_camelotRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            p.amountIn,
            0,
            path,
            p.recipient,
            p.recipient,
            p.deadline
        );
    }

    function _swapCamelotV3(SwapParams memory p) public {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_camelotV3Router), p.amountIn);

        (uint24 fee, uint160 limitSqrtPrice, uint256 amountOutMinimum) = abi.decode(p.extra, (uint24, uint160, uint256));

        ISwapRouterCamelotV3.ExactInputSingleParams memory params = ISwapRouterCamelotV3.ExactInputSingleParams({
            tokenIn: p.tokenIn,
            tokenOut: p.tokenOut,
            recipient: p.recipient,
            amountIn: p.amountIn,
            deadline: p.deadline,
            amountOutMinimum: amountOutMinimum,
            limitSqrtPrice: limitSqrtPrice
        });

        i_camelotV3Router.exactInputSingle(params);
    }

    function _ensureAllowance(address token, address spender, uint256 amount) internal {
        uint256 current = IERC20(token).allowance(address(this), spender);
        if (current < amount) {
            // universal-safe pattern for USDT-like tokens
            IERC20(token).approve(spender, 0);
            IERC20(token).approve(spender, type(uint256).max);
        }
    }



    receive() external payable {}
}

