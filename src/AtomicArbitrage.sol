// SPDX-License_Identifier: MIT
pragma solidity =0.8.20;

// Interfaces
import {IWETH9} from "./interfaces/IWETH9.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {ISwapRouter02} from "./interfaces/ISwapRouter02.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {ICamelotRouter} from "./interfaces/ICamelotRouter.sol";
import {ISwapRouterCamelotV3} from "./interfaces/ISwapRouterCamelotV3.sol";
import{IPancakeRouter01PancakeswapV2} from "./interfaces/IPancakeRouter01PancakeswapV2.sol";
import{ISwapRouterPanckeswapV3} from "./interfaces/ISwapRouterPanckeswapV3.sol";

contract AtomicArbitrage {
    /**
     * ERR0: Only owner can call this function
     * ERR1: Only supports pairs that have WETH as one of the tokens
     * ERR2: Exchange not supported
     * ERR3: Invalid token address
     * ERR4: Invalid router address
     * ERR5: Not a contract
     * ERR6: No profit
     */
    address private immutable i_owner;

    IWETH9 private immutable i_WETH9;
    IUniswapV2Router02 private immutable i_uniswapV2Router02;
    ISwapRouter02 private immutable i_uniswapV3Router;
    IUniswapV2Router02 private immutable i_sushiswapV2Router02;
    ISwapRouter private immutable i_sushiswapV3Router;
    ICamelotRouter private immutable i_camelotRouter;
    ISwapRouterCamelotV3 private immutable i_camelotV3Router;
    IPancakeRouter01PancakeswapV2 private immutable i_pancakeswapV2Router02;
    ISwapRouterPanckeswapV3 private immutable i_pancakeswapV3Router;



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

    // Address validation helpers
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _requireContract(address account) internal view {
        require(account != address(0), "ERR4");  // zero address
        require(_isContract(account), "ERR5");   // not a deployed contract
    }

    constructor(
        address WETH9Address,
        address idx0_address, // UniswapV2Router02 address
        address idx1_address, // UniswapV3SwapRouter address
        address idx2_address, // SushiswapV2Router02 address
        address idx3_address, // SushiswapV3SwapRouter address
        address idx4_address, // CamelotV2Router address
        address idx5_address, // CamelotV3SwapRouter address
        address idx6_address, // PancakeswapV2Router02 address
        address idx7_address  // PancakeswapV3SwapRouter address
    ) {
        i_owner = msg.sender;

        // Validate inputs: non-zero and deployed contracts
        _requireContract(WETH9Address);
        _requireContract(idx0_address);
        _requireContract(idx1_address);
        _requireContract(idx2_address);
        _requireContract(idx3_address);
        _requireContract(idx4_address);
        _requireContract(idx5_address);
        _requireContract(idx6_address);
        _requireContract(idx7_address);

        i_WETH9 = IWETH9(WETH9Address);
        i_uniswapV2Router02 = IUniswapV2Router02(idx0_address);
        i_uniswapV3Router = ISwapRouter02(idx1_address);
        i_sushiswapV2Router02 = IUniswapV2Router02(idx2_address);
        i_sushiswapV3Router = ISwapRouter(idx3_address);
        i_camelotRouter = ICamelotRouter(idx4_address);
        i_camelotV3Router = ISwapRouterCamelotV3(idx5_address);
        i_pancakeswapV2Router02 = IPancakeRouter01PancakeswapV2(idx6_address);
        i_pancakeswapV3Router = ISwapRouterPanckeswapV3(idx7_address);
    }

    /**
     * @notice Executes a two-leg atomic arbitrage between two exchanges to increase the primary token balance (currently WETH).
     * @dev Only callable by the owner. Wraps `amountIn` ETH to WETH, swaps WETH→medium on `idx1`, swaps medium→WETH on `idx2`,
     *      then unwraps and sends ETH back to the owner. `primaryTokenAddress` must equal the configured WETH9 address.
     * @param idx1 Index of the first exchange/router:
     *             0=UniswapV2, 1=UniswapV3, 2=SushiV2, 3=SushiV3, 4=CamelotV2, 5=CamelotV3, 6=PancakeV2, 7=PancakeV3.
     * @param idx2 Index of the second exchange/router; uses the same mapping as `idx1`.
     * @param amountIn Amount of primary token to start with (WETH). Must also be provided as `msg.value` for the initial wrap.
     * @param primaryTokenAddress Address of the primary token (must be WETH9 in current implementation).
     * @param mediumTokenAddress Address of the intermediate token (e.g., USDC/USDT).
     * @param extra1 ABI-encoded per-exchange config for the first leg:
     *               - idx1 in {1,3,7} (V3): encode (uint24 fee, uint160 sqrtPriceLimitX96, uint256 amountOutMinimum).
     *               - idx1 == 5 (Camelot V3): encode (uint160 limitSqrtPrice, uint256 amountOutMinimum).
     *               - idx1 in {0,2,4,6} (V2): pass empty bytes `0x`.
     *               Note: `amountOutMinimum` is in the output token’s decimals for that leg.
     * @param extra2 ABI-encoded per-exchange config for the second leg (same layout rules as `extra1`, based on `idx2`).
     * @param imposeProfit If true, the call reverts unless the second leg returns more WETH than `amountIn`.
     * @return profit Signed net change in primary token after both swaps; negative values indicate loss when `imposeProfit` is false.
     */
    function makeArb(
        uint idx1,
        uint idx2,
        uint256 amountIn,
        address primaryTokenAddress,
        address mediumTokenAddress,
        bytes calldata extra1,
        bytes calldata extra2,
        bool imposeProfit
    ) external onlyOwner payable returns (int256) {
        // Currently supports pairs that have WETH as one of the tokens. The goal is to increase the primary token balance.
        if (primaryTokenAddress != address(i_WETH9)) {
            revert("ERR1"); // TODO: Add support for other primary tokens
        }

        // Returned amount of the first trade
        uint256 out1;
        uint256 out2;

        // 1. Weap ETH to WETH
        _wrapETH(amountIn);

        // 2. Sell WETH for the medium token in the first pool
        SwapParams memory p1 = SwapParams({
            tokenIn: primaryTokenAddress,
            tokenOut: mediumTokenAddress,
            amountIn: amountIn,
            recipient: address(this),
            deadline: block.timestamp + 120000,
            extra: extra1
        });
        out1 = _makeSwap(idx1, p1);

        // 3. Sell the medium token for WETH in the second pool
        SwapParams memory p2 = SwapParams({
            tokenIn: mediumTokenAddress,
            tokenOut: primaryTokenAddress,
            amountIn: out1,
            recipient: address(this),
            deadline: block.timestamp + 120000,
            extra: extra2
        });
        out2 = _makeSwap(idx2, p2);

        if(imposeProfit) {
            require(out2 > amountIn, "ERR6");
        }

        // 4. Unwrap WETH to ETH
        _unwrapETH(out2);

        return int256(out2) - int256(amountIn);
    }

    /**
     *
    * Makes an arbitrage without wrapping eth.
    */
    function makeTokenArb(
        uint idx1,
        uint idx2,
        uint256 amountIn,
        address primaryTokenAddress,
        address mediumTokenAddress,
        bytes calldata extra1,
        bytes calldata extra2,
        bool imposeProfit
    ) external onlyOwner returns (int256) {
        // Initial declarations
        uint256 out1;
        uint256 out2;

        // 1. Sell WETH for the medium token in the first pool
        SwapParams memory p1 = SwapParams({
            tokenIn: primaryTokenAddress,
            tokenOut: mediumTokenAddress,
            amountIn: amountIn,
            recipient: address(this),
            deadline: block.timestamp + 120000,
            extra: extra1
        });
        out1 = _makeSwap(idx1, p1);

        // 2. Sell the medium token for WETH in the second pool
        SwapParams memory p2 = SwapParams({
            tokenIn: mediumTokenAddress,
            tokenOut: primaryTokenAddress,
            amountIn: out1,
            recipient: address(this),
            deadline: block.timestamp + 120000,
            extra: extra2
        });
        out2 = _makeSwap(idx2, p2);

        if(imposeProfit) {
            require(out2 > amountIn, "ERR6");
        }

        return int256(out2) - int256(amountIn);
    }

    /**
     *
    * Makes a token arbitrage from wallet.
    */
    function makeTokenArbFromWallet(
        uint idx1,
        uint idx2,
        uint256 amountIn,
        address primaryTokenAddress,
        address mediumTokenAddress,
        bytes calldata extra1,
        bytes calldata extra2,
        bool imposeProfit
    ) external onlyOwner returns (int256) {
        // Initial declarations
        uint256 out1;
        uint256 out2;

        // 1. Pull token from wallet
        bool ok = IERC20(primaryTokenAddress).transferFrom(msg.sender, address(this), amountIn);
        require(ok, "TRANSFER_FROM_USER_FAILED");

        // 2. Sell WETH for the medium token in the first pool
        SwapParams memory p1 = SwapParams({
            tokenIn: primaryTokenAddress,
            tokenOut: mediumTokenAddress,
            amountIn: amountIn,
            recipient: address(this),
            deadline: block.timestamp + 120000,
            extra: extra1
        });
        out1 = _makeSwap(idx1, p1);

        // 3. Sell the medium token for WETH in the second pool
        SwapParams memory p2 = SwapParams({
            tokenIn: mediumTokenAddress,
            tokenOut: primaryTokenAddress,
            amountIn: out1,
            recipient: address(this),
            deadline: block.timestamp + 120000,
            extra: extra2
        });
        out2 = _makeSwap(idx2, p2);

        if(imposeProfit) {
            require(out2 > amountIn, "ERR6");
        }

        // 4. Send token back to owner
        ok = IERC20(primaryTokenAddress).transfer(msg.sender, out2);
        require(ok, "TRANSFER_TO_USER_FAILED");

        return int256(out2) - int256(amountIn);
    }

    /**
     * Wraps ether to WETH
     * @param amount - The amount to wrap
     */
    function _wrapETH(uint256 amount) public payable onlyOwner {
        require(msg.value == amount, "ERRORWRAP");
        i_WETH9.deposit{value: amount}();
    }

    /**
     * Unwraps WETH to ether and sends it to the owner
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
    function _makeSwap(uint idx, SwapParams memory p) public onlyOwner returns (uint256) {
        uint256 returnAmount;
        if        (idx == 0) {
            returnAmount = _swapUniswapV2(p);
        } else if (idx == 1) {
            returnAmount = _swapUniswapV3(p);
        } else if (idx == 2) {
            returnAmount =_swapSushiswapV2(p);
        } else if (idx == 3) {
            returnAmount =_swapSushiswapV3(p);
        } else if (idx == 4) {
            returnAmount =_swapCamelotV2(p);
        } else if (idx == 5) {
            returnAmount =_swapCamelotV3(p);
        } else if (idx == 6) {
            returnAmount =_swapPancakeswapV2(p);
        } else if (idx == 7) {
            returnAmount =_swapPancakeswapV3(p);
        } else {
            revert("ERR2");
        }

        return returnAmount;
    }

    function _swapUniswapV2(SwapParams memory p) public onlyOwner returns (uint256) {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_uniswapV2Router02), p.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = p.tokenIn;
        path[1] = p.tokenOut;
        
        uint[] memory amountsOut = i_uniswapV2Router02.swapExactTokensForTokens(
            p.amountIn,
            0,
            path,
            p.recipient,
            p.deadline
        );

        // The first element is the input amount, the rest are the subsequent output amounts
        return amountsOut[1];
    }

    function _swapUniswapV3(SwapParams memory p) public onlyOwner returns (uint256) {
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

        return i_uniswapV3Router.exactInputSingle(params);
    }

    function _swapSushiswapV2(SwapParams memory p) public onlyOwner returns (uint256) {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_sushiswapV2Router02), p.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = p.tokenIn;
        path[1] = p.tokenOut;
        
        uint[] memory amountsOut = i_sushiswapV2Router02.swapExactTokensForTokens(
            p.amountIn,
            0,
            path,
            p.recipient,
            p.deadline
        );

        // The first element is the input amount, the rest are the subsequent output amounts
        return amountsOut[1];
    }

    function _swapSushiswapV3(SwapParams memory p) public onlyOwner  returns (uint256) {
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

        return i_sushiswapV3Router.exactInputSingle(params);
    }

    function _swapCamelotV2(SwapParams memory p) public onlyOwner  returns (uint256) {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_camelotRouter), p.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = p.tokenIn;
        path[1] = p.tokenOut;

        // Camelot v2 doesnt return any amounts after making a swap! So we need to calculate the output amount manually
        uint256 balanceBefore = IERC20(p.tokenOut).balanceOf(p.recipient);
        i_camelotRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            p.amountIn,
            0,
            path,
            p.recipient,
            p.recipient,
            p.deadline
        );
        uint256 balanceAfter = IERC20(p.tokenOut).balanceOf(p.recipient);

        // The first element is the input amount, the rest are the subsequent output amounts
        return balanceAfter - balanceBefore;
    }

    function _swapCamelotV3(SwapParams memory p) public onlyOwner returns (uint256) {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_camelotV3Router), p.amountIn);

        (uint160 limitSqrtPrice, uint256 amountOutMinimum) = abi.decode(p.extra, (uint160, uint256));

        ISwapRouterCamelotV3.ExactInputSingleParams memory params = ISwapRouterCamelotV3.ExactInputSingleParams({
            tokenIn: p.tokenIn,
            tokenOut: p.tokenOut,
            recipient: p.recipient,
            amountIn: p.amountIn,
            deadline: p.deadline,
            amountOutMinimum: amountOutMinimum,
            limitSqrtPrice: limitSqrtPrice
        });

        return i_camelotV3Router.exactInputSingle(params);
    }

    function _swapPancakeswapV2(SwapParams memory p) public onlyOwner returns (uint256){
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_pancakeswapV2Router02), p.amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = p.tokenIn;
        path[1] = p.tokenOut;
        
        uint[] memory amountsOut = i_pancakeswapV2Router02.swapExactTokensForTokens(
            p.amountIn,
            0,
            path,
            p.recipient,
            p.deadline
        );

        // The first element is the input amount, the rest are the subsequent output amounts
        return amountsOut[1];
    }

    function _swapPancakeswapV3(SwapParams memory p) public onlyOwner returns (uint256) {
        // Ensiure allowance. TODO: Remove this?
        _ensureAllowance(p.tokenIn, address(i_pancakeswapV3Router), p.amountIn);

        (uint24 fee, uint160 sqrtPriceLimitX96, uint256 amountOutMinimum) = abi.decode(p.extra, (uint24, uint160, uint256));

        ISwapRouterPanckeswapV3.ExactInputSingleParams memory params = ISwapRouterPanckeswapV3.ExactInputSingleParams({
            tokenIn: p.tokenIn,
            tokenOut: p.tokenOut,
            fee: fee,
            recipient: p.recipient,
            amountIn: p.amountIn,
            deadline: p.deadline,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        return i_pancakeswapV3Router.exactInputSingle(params);
    }

    function _ensureAllowance(address token, address spender, uint256 amount) internal {
        uint256 current = IERC20(token).allowance(address(this), spender);
        if (current < amount) {
            // universal-safe pattern for USDT-like tokens
            IERC20(token).approve(spender, 0);
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    /**
     * @notice Deposit any ERC20 token into the contract.
     * @dev Caller must approve this contract to spend `amount` beforehand.
     * @param token The ERC20 token address to deposit.
     * @param amount The amount to deposit.
     * @return ok True if transfer succeeded.
     */
    function _depositToken(address token, uint256 amount) external onlyOwner returns (bool ok) {
        _requireContract(token);
        require(amount > 0, "AMOUNT_ZERO");
        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= amount, "ALLOWANCE_LOW");
        ok = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(ok, "TRANSFER_FROM_FAILED");
    }

    /**
     * @notice Withdraw any ERC20 token from the contract to the owner.
     * @dev Only callable by owner; tokens are sent to `i_owner`.
     * @param token The ERC20 token address to withdraw.
     * @param amount The amount to withdraw.
     * @return ok True if transfer succeeded.
     */
    function _withdrawToken(address token, uint256 amount) external onlyOwner returns (bool ok) {
        _requireContract(token);
        require(amount > 0, "AMOUNT_ZERO");
        require(IERC20(token).balanceOf(address(this)) >= amount, "INSUFFICIENT_BALANCE");
        ok = IERC20(token).transfer(i_owner, amount);
        require(ok, "TRANSFER_FAILED");
    }

    receive() external payable {}
}

