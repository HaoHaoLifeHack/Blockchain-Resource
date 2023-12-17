pragma solidity 0.8.19;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IUniswapV2Callee} from "v2-core/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Factory} from "v2-core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
import {CErc20} from "compound-protocol/contracts/CErc20.sol";

contract FlashSwapLiquidate is IUniswapV2Callee {
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CErc20 public cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    CErc20 public cDAI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    IUniswapV2Router02 public router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Factory public factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    // Call swap on pair to get USDC
    // Repay Jakc’s USDC debt
    // 得到 cDai
    // cDai -> Dai
    // Transfer Dai to pair

    // amount0 是地址比較小的 => amount0: DAI: 0x6B... / amount1: USDC: 0xA0b...
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        // TODO
        //  * @param borrower The borrower of this cToken to be liquidated
        //  * @param repayAmount The amount of the underlying borrowed asset to repay
        //  * @param cTokenCollateral The market in which to seize collateral from the borrower
        //  * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
        address borrower = abi.decode(data, (address));
        // calculate amountIn by router
        // getAmountsIn(uint amountOut, address[] memory path)
        // path = [DAI, USDC]
        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(USDC);

        IERC20(USDC).approve(address(cUSDC), amount1); //amount1: USDC repayAmount
        cUSDC.liquidateBorrow(borrower, amount1, cDAI);
        cDAI.redeem(cDAI.balanceOf(address(this)));
        uint256 amountIn = router.getAmountsIn(amount1, path)[0]; //use USDC repayAmount to DAI amountIn which the liquidator should repay V2Pair
        //the remainning amount is DAI is the profit of liquidator
        DAI.transfer(
            address(factory.getPair(address(DAI), address(USDC))),
            amountIn
        );
    }

    function liquidate(address borrower, uint256 amountOut) external {
        // TODO
        address pair = factory.getPair(address(DAI), address(USDC));
        //  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
        IUniswapV2Pair(pair).swap(
            0,
            amountOut,
            address(this),
            abi.encode(borrower)
        );
    }
}
