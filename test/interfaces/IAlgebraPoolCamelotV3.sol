pragma solidity >=0.5.0;

interface IAlgebraPoolCamelotV3 {
    function dataStorageOperator() external view returns (address);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function maxLiquidityPerTick() external view returns (uint128);

    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 fee,
            uint16 timepointIndex,
            uint8 communityFeeToken0,
            uint8 communityFeeToken1,
            bool unlocked
        );

    function totalFeeGrowth0Token() external view returns (uint256);

    function totalFeeGrowth1Token() external view returns (uint256);

    function liquidity() external view returns (uint128);

    function ticks(
        int24 tick
    )
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int56 outerTickCumulative,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool initialized
        );

    function tickTable(int16 wordPosition) external view returns (uint256);

    function positions(
        bytes32 key
    )
        external
        view
        returns (
            uint128 liquidityAmount,
            uint32 lastLiquidityAddTimestamp,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );

    function timepoints(
        uint256 index
    )
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint88 volatilityCumulative,
            int24 averageTick,
            uint144 volumePerLiquidityCumulative
        );

    function activeIncentive() external view returns (address virtualPool);

    function liquidityCooldown()
        external
        view
        returns (uint32 cooldownInSeconds);

    function tickSpacing() external view returns (int24);
    function getTimepoints(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    function getInnerCumulatives(
        int24 bottomTick,
        int24 topTick
    )
        external
        view
        returns (
            int56 innerTickCumulative,
            uint160 innerSecondsSpentPerLiquidity,
            uint32 innerSecondsSpent
        );

    function initialize(uint160 price) external;

    function mint(
        address sender,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount,
        bytes calldata data
    )
        external
        returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);

    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function burn(
        int24 bottomTick,
        int24 topTick,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function swapSupportingFeeOnInputTokens(
        address sender,
        address recipient,
        bool zeroToOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

    /// @notice Set the new tick spacing values. Only factory owner
    /// @param newTickSpacing The new tick spacing value
    function setTickSpacing(int24 newTickSpacing) external;

    function setIncentive(address virtualPoolAddress) external;

    function setLiquidityCooldown(uint32 newLiquidityCooldown) external;

    event Initialize(uint160 price, int24 tick);

    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );

    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );

    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 price,
        uint128 liquidity,
        int24 tick
    );

    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    event CommunityFee(uint8 communityFee0New, uint8 communityFee1New);

    event TickSpacing(int24 newTickSpacing);

    event Incentive(address indexed virtualPoolAddress);

    event Fee(uint16 fee);

    event LiquidityCooldown(uint32 liquidityCooldown);
}
