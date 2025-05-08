// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import { console } from "forge-std/Test.sol";

import { IERC20, ICoolerFactory, IAaveFlashloan, ICooler, ISwapRouter, IUniswapV3Factory } from "./interfaces/IRescueFlashloaner.sol";
contract RescueFlashloaner {
    address immutable owner;
    address immutable aave;
    address immutable gOHM;
    address immutable usds;
    address immutable coolerFactory;
    address immutable victim;
    address immutable loanConsolidation;
    address immutable clearingHouse;
    address immutable rescueRecipient;
    address public rescueCooler;
    
    constructor(
        address _aaveAddress, 
        address _gOHM, 
        address _usdsAddress,
        address _coolerFactory,
        address _loanConsolidation,
        address _clearingHouse,
        address _victim,
        address _owner,
        address _rescueRecipient
        ) {
        aave = _aaveAddress;
        gOHM = _gOHM;
        usds = _usdsAddress;
        coolerFactory = _coolerFactory;
        loanConsolidation = _loanConsolidation;
        clearingHouse = _clearingHouse;
        victim = _victim;
        rescueRecipient = _rescueRecipient;
        owner = _owner;

        rescueCooler = ICoolerFactory(coolerFactory).generateCooler({
            _collateralAddress: gOHM,
            _debtAddress: usds
        });
        IERC20(_usdsAddress).approve(_loanConsolidation, type(uint256).max);
        // Anything we do in storage in constructor using 7702 
        // won't be applied to the delegation as this is an implementation contract
    }

    function _is7702() internal view returns (bool) {
        return owner == address(this); // owner == victim 
    }

    function fundVictim() payable external {
        require(msg.sender == owner, "I don't know you");
        require(!_is7702(), "Nice try sweeper");
        IERC20(gOHM).transfer(victim, IERC20(gOHM).balanceOf(address(this)));
        IERC20(usds).transfer(victim, IERC20(usds).balanceOf(address(this)));
        (bool success, ) = victim.call{value: 0.008 ether}("");
        require(success, "Transfer to victim failed");
    }

    function swipe() public {
        require(msg.sender == owner, "I don't know you");
        IERC20(gOHM).transfer(rescueRecipient, IERC20(gOHM).balanceOf(address(this)));
        IERC20(usds).transfer(rescueRecipient, IERC20(usds).balanceOf(address(this)));
        rescueRecipient.call{value: address(this).balance}("");
    }

    function rescue() external {
        require(msg.sender == owner, "I don't know you");

        if (rescueCooler == address(0)) {
            rescueCooler = ICoolerFactory(coolerFactory).generateCooler({
                _collateralAddress: gOHM,
                _debtAddress: usds
            });
        }



        IAaveFlashloan(aave).flashLoanSimple({
            receiverAddress: address(this),
            asset: usds,
            amount: 5500 * 1e18,
            params: "",
            referralCode: 0
        });    

      block.coinbase.call{value: 0.001 ether}("");
      // Log balance left
      // console.log("Balance Left", address(this).balance);
      swipe();
      
      uint rescued = IERC20(usds).balanceOf(rescueRecipient);
      require(rescued > 0, "Rescue failed");
      
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata
    ) external returns (bool) {
        require(msg.sender == aave, "Only Aave");
        require(initiator == address(this), "Only this contract");

        // Doing rescue here, we repay our Cooler debt
        // and then we pay back the flashloan
        IERC20(usds).approve(rescueCooler, type(uint256).max);

        // Log balance
        uint256 balance = IERC20(usds).balanceOf(address(this));
        // console.log("RescueFlashloaner USDS balance before repayLoan ", balance);

        // If delegated pay only the consolidated loan
        // If not, pay all loans
        
        ICooler(rescueCooler).repayLoan({
            loanID_: 0,
            repayment_: type(uint112).max
        });

        if (victim == address(this)) {
            // If this contract is the victim, it means we're in a 7702 context
            ICooler(rescueCooler).repayLoan({
                loanID_: 1,
                repayment_: type(uint112).max
            });
            ICooler(rescueCooler).repayLoan({
                loanID_: 2,
                repayment_: type(uint112).max
            });
        }

        balance = IERC20(usds).balanceOf(address(this));
        // console.log("RescueFlashloaner USDS balance AFTER repayLoan ", balance);

        // console.log("RescueFlashloaner OHM balance after  repayLoan ", IERC20(gOHM).balanceOf(address(this)));

        _unStakeAndSwap();

        balance = IERC20(usds).balanceOf(address(this));
        // console.log("RescueFlashloaner USDS balance AFTER __unStakeAndSwap ", balance);

        uint256 totalRepayment = amount + premium;

        require(asset == usds, "Invalid asset");
        uint profit = IERC20(asset).balanceOf(address(this)) - totalRepayment;
        require(profit > 4000*10**18, "No profit");
        console.log("Profit: ", profit);

        require(IERC20(asset).balanceOf(address(this)) >= totalRepayment, "Not enough USDS to repay");

        IERC20(asset).approve(aave, type(uint256).max); // AAVE Will pay itself
        return true;
    }

    function _unStakeAndSwap() internal {

        // Unstake gOHM from Olympus Staking
        address OLYMPUS_STAKING_V2 = 0xB63cac384247597756545b500253ff8E607a8020;
        IERC20(gOHM).approve(OLYMPUS_STAKING_V2, type(uint256).max);
        bytes memory unstakeData = abi.encodeWithSignature(
            "unstake(address,uint256,bool,bool)",
            address(this),
            IERC20(gOHM).balanceOf(address(this)),
            false,
            false
        );

        (bool success, ) = OLYMPUS_STAKING_V2.call(unstakeData);
        require(success, "Unstake failed");
        // console.log("UNSTAKE OK");

        // Log OHM balance after unstake
        address OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
        uint OHMAmount = IERC20(OHM).balanceOf(address(this));


        address WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address UNI_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        IERC20(OHM).approve(UNI_V3_ROUTER, OHMAmount);

        bytes memory path = abi.encodePacked(
            OHM,
            uint24(3000),
            WETH_ADDRESS,
            uint24(3000),
            DAI,
            uint24(3000),
            usds
        );

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp + 60,
            amountIn: OHMAmount,
            amountOutMinimum: 0 // yolo slippage
        });

        address factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984; // Uniswap V3 factory
        address pool = IUniswapV3Factory(factory).getPool(WETH_ADDRESS, OHM, 3000);
        pool = IUniswapV3Factory(factory).getPool(usds, WETH_ADDRESS, 3000);
        pool = IUniswapV3Factory(factory).getPool(usds, USDC, 3000);

        // console.log(">> RescueFlashloaner USDS balance BEFORE swap ", IERC20(usds).balanceOf(address(this)));
        uint amountOut = ISwapRouter(UNI_V3_ROUTER).exactInput(params);
        // console.log(">> RescueFlashloaner USDS balance after swap ", amountOut);

        require(amountOut > 0, "Swap failed");
     

        // Log USDS balance after swap
        // uint256 usdsBalance = IERC20(usds).balanceOf(address(this));
    }


}
