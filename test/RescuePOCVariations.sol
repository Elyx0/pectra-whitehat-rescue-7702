// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";

import { IERC20, ICoolerFactory, RescueFlashloaner } from "../src/RescueFlashloaner.sol";

import { IClearinghouse } from "../src/interfaces/IClearingHouse.sol";
import { ILoanConsolidator } from "../src/interfaces/ILoanConsolidator.sol";

abstract contract BaseEnv {
    IClearinghouse public clearingHouse;
    ILoanConsolidator public loanConsolidator;
    address public VICTIM_ADDRESS;
    address public USDS_ADDRESS;
    address public CLEARING_HOUSE_ADDRESS;
    address public GOHM_ADDRESS;
    address public LOAN_CONSOLIDATION_ADDRESS;
    address public RESCUE_ADDRESS;
    address public AAVE_ADDRESS;
    address public COOLER_FACTORY_ADDRESS;
    address public RESCUE_RECIPIENT_ADDRESS;

    function _loadEnv(VmSafe vm) internal {
        string memory victim_address_str = "VICTIM_ADDRESS";
        string memory usds_address_str = "USDS_ADDRESS";
        string memory clearing_house_address_str = "CLEARING_HOUSE_ADDRESS";
        string memory gohm_address_str = "GOHM_ADDRESS";
        string memory loan_consolidation_address_str = "LOAN_CONSOLIDATION_ADDRESS";
        string memory rescue_address_str = "RESCUE_ADDRESS";
        string memory aave_address_str = "AAVE_V3_MAINNET_ADDRESS";
        string memory cooler_factory_address_str = "COOLER_FACTORY_ADDRESS";
        string memory rescue_recipient_address_str = "RESCUE_RECIPIENT_ADDRESS";

        VICTIM_ADDRESS = vm.envAddress(victim_address_str);
        USDS_ADDRESS = vm.envAddress(usds_address_str);
        CLEARING_HOUSE_ADDRESS = vm.envAddress(clearing_house_address_str);
        GOHM_ADDRESS = vm.envAddress(gohm_address_str);
        LOAN_CONSOLIDATION_ADDRESS = vm.envAddress(loan_consolidation_address_str);
        RESCUE_ADDRESS = vm.envAddress(rescue_address_str);
        AAVE_ADDRESS = vm.envAddress(aave_address_str);
        COOLER_FACTORY_ADDRESS = vm.envAddress(cooler_factory_address_str);
        RESCUE_RECIPIENT_ADDRESS = vm.envAddress(rescue_recipient_address_str);

        vm.label(VICTIM_ADDRESS, victim_address_str);
        vm.label(USDS_ADDRESS, usds_address_str);
        vm.label(CLEARING_HOUSE_ADDRESS, clearing_house_address_str);
        vm.label(GOHM_ADDRESS, gohm_address_str);
        vm.label(LOAN_CONSOLIDATION_ADDRESS, loan_consolidation_address_str);
        vm.label(RESCUE_ADDRESS, rescue_address_str);
        vm.label(AAVE_ADDRESS, aave_address_str);
        vm.label(COOLER_FACTORY_ADDRESS, cooler_factory_address_str);
        vm.label(RESCUE_RECIPIENT_ADDRESS, rescue_recipient_address_str);

        vm.label(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, "WETH");
        vm.label(0xE592427A0AEce92De3Edee1F18E0157C05861564, "UNI_V3_ROUTER");
        vm.label(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5, "OHM");
        vm.label(0xB63cac384247597756545b500253ff8E607a8020, "OLYMPUS_STAKING_V2");
        vm.label(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, "USDC");
        
    }
}

contract RescuePOCVariationsTest is Test, BaseEnv {
    function setUp() public {
        _loadEnv(vm);
        
        // Fork the mainnet
        vm.createSelectFork("mainnet", 22432155);

        // Someone funds RESCUE_ADDRESS with 0.02 ETH
        vm.deal(RESCUE_ADDRESS, 0.02 ether);
    }

    function test_Rescue_normal() public {

        // PRE-RESCUE
        vm.prank(RESCUE_ADDRESS); // FUND IT
        RescueFlashloaner RESCUE_FLASHLOANER = new RescueFlashloaner({
            _aaveAddress: AAVE_ADDRESS,
            _gOHM: GOHM_ADDRESS,
            _usdsAddress: USDS_ADDRESS,
            _coolerFactory: COOLER_FACTORY_ADDRESS,
            _loanConsolidation: LOAN_CONSOLIDATION_ADDRESS,
            _clearingHouse: CLEARING_HOUSE_ADDRESS,
            _victim: VICTIM_ADDRESS,
            _owner: RESCUE_ADDRESS, // VICTIM_ADDRESS in 7702 case
            _rescueRecipient: RESCUE_RECIPIENT_ADDRESS
        });

        console.log("Implementation will exist at address: ", address(RESCUE_FLASHLOANER));
        // PRE-RESCUE - POST RESCUE_FLASHLOANER DEPLOYMENT
        // RESCUE_FLASHLOANER needs to have some USDS and gOHM in its account 
        // to pay for consolidateWithNewOwner
        deal(USDS_ADDRESS, address(RESCUE_FLASHLOANER), 15 * 1e18, false);
        deal(GOHM_ADDRESS, address(RESCUE_FLASHLOANER), 1 * 1e18, false);



        // BUNDLE TX 1 (RESCUE ADDRESS SENDS 0.001 ETH TO VICTIM + USDS & gOHM)
        // by calling fundVictim() on the RescueFlashloaner contract
        vm.prank(RESCUE_ADDRESS);
        RescueFlashloaner(RESCUE_FLASHLOANER).fundVictim{value: 0.01 ether}();

        // BUNDLE TX 2 (CONSOLIDATE LOANS WITH NEW OWNER BEING THE RESCUE FLASHLOANER)
        vm.startPrank(VICTIM_ADDRESS);

        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        address coolerOfRescueContract = RESCUE_FLASHLOANER.rescueCooler();
        vm.label(coolerOfRescueContract, "CoolerOfRescueContract");

        // bytes memory data = abi.encodeWithSignature(
        //     "consolidateWithNewOwner(address,address,address,address,uint256[])",
        //     CLEARING_HOUSE_ADDRESS,
        //     CLEARING_HOUSE_ADDRESS,
        //     ICoolerFactory(COOLER_FACTORY_ADDRESS).getCoolerFor({
        //         user_: VICTIM_ADDRESS,
        //         collateral_: GOHM_ADDRESS,
        //         debt_: USDS_ADDRESS
        //     }),
        //     RESCUE_FLASHLOANER.rescueCooler(),
        //     ids
        // );
        //console.logBytes(data);

        ILoanConsolidator(LOAN_CONSOLIDATION_ADDRESS).consolidateWithNewOwner({
            clearinghouseFrom_: CLEARING_HOUSE_ADDRESS,
            clearinghouseTo_: CLEARING_HOUSE_ADDRESS,
            coolerFrom_: ICoolerFactory(COOLER_FACTORY_ADDRESS).getCoolerFor({
                user_: VICTIM_ADDRESS,
                collateral_: GOHM_ADDRESS,
                debt_: USDS_ADDRESS
            }),
            coolerTo_: RESCUE_FLASHLOANER.rescueCooler(),
            ids_: ids
        });
        
        vm.stopPrank();


        // BUNDLE TX 3 FLASH LOAN to pay off the loans
        // Now RESCUE_FLASHLOANER owns the loan, and can flashloan because it's not an EOA.
        vm.startPrank(RESCUE_ADDRESS);
        RESCUE_FLASHLOANER.rescue();

        console.log("RescueFlashloaner balance after consolidation: ", IERC20(USDS_ADDRESS).balanceOf(address(RESCUE_FLASHLOANER)));
    }

    function test_Rescue_7702() external {
        //  Same as test_Rescue_normal but with 7702
        //  - GenerateCooler will return existing cooler
        //  - No need to consolidateWithNewOwner
        //  - No need to fundVictim or have gOHM / USDS to consolidate 

        // PRE-RESCUE
        // Deploy implementation
        vm.startPrank(RESCUE_ADDRESS);
        RescueFlashloaner RESCUE_FLASHLOANER = new RescueFlashloaner({
            _aaveAddress: AAVE_ADDRESS,
            _gOHM: GOHM_ADDRESS,
            _usdsAddress: USDS_ADDRESS,
            _coolerFactory: COOLER_FACTORY_ADDRESS,
            _loanConsolidation: LOAN_CONSOLIDATION_ADDRESS,
            _clearingHouse: CLEARING_HOUSE_ADDRESS,
            _victim: VICTIM_ADDRESS,
            _owner: RESCUE_ADDRESS,
            _rescueRecipient: RESCUE_RECIPIENT_ADDRESS
        });
     
        console.log("Implementation will exist at address: ", address(RESCUE_FLASHLOANER));

        // RESCUE BUNDLE TX - 1 shot
        vm.signAndAttachDelegation(address(RESCUE_FLASHLOANER), vm.envUint("VICTIM_PRIVATE_KEY"));
        // vm.etch(VICTIM_ADDRESS, bytes.concat(hex"ef0100", abi.encodePacked(address(RESCUE_FLASHLOANER))));

        // Now the VICTIM is a RescueFlashloaner! Call the victim.
        RescueFlashloaner(VICTIM_ADDRESS).rescue();

        console.log("RESCUE_RECIPIENT_ADDRESS USDS after rescue: ", IERC20(USDS_ADDRESS).balanceOf(address(RESCUE_RECIPIENT_ADDRESS)));
        // 
        // Done !!

        // [PASS] test_Rescue_7702() (gas: 3533588)
        // Logs:
        // Implementation will exist at address:  0x97f6C7F4110aFe7DD51d987EE1fa03f01c933834
        // Profit:  4094761451052853226443
        // RESCUE_RECIPIENT_ADDRESS USDS after rescue:  4094761451052853226443

        // [PASS] test_Rescue_normal() (gas: 4735732)
        // Logs:
        // Implementation will exist at address:  0x97f6C7F4110aFe7DD51d987EE1fa03f01c933834
        // Profit:  4094678066859123226047
    }
}
