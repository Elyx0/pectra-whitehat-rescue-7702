// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IClearinghouse {
    type Keycode is bytes5;

    struct Permissions {
        Keycode keycode;
        bytes4 funcSelector;
    }

    error BadEscrow();
    error DurationMaximum();
    error KernelAdapter_OnlyKernel(address caller_);
    error LengthDiscrepancy();
    error NotLender();
    error OnlyBorrower();
    error OnlyBurnable();
    error OnlyFromFactory();
    error Policy_ModuleDoesNotExist(Keycode keycode_);
    error Policy_WrongModuleVersion(bytes expected_);
    error TooEarlyToFund();

    event Activate();
    event Deactivate();
    event Defund(address token, uint256 amount);
    event Rebalance(bool defund, uint256 reserveAmount);

    function CHREG() external view returns (address);
    function DURATION() external view returns (uint256);
    function FUND_AMOUNT() external view returns (uint256);
    function FUND_CADENCE() external view returns (uint256);
    function INTEREST_RATE() external view returns (uint256);
    function LOAN_TO_COLLATERAL() external view returns (uint256);
    function MAX_REWARD() external view returns (uint256);
    function MINTR() external view returns (address);
    function ROLES() external view returns (address);
    function TRSRY() external view returns (address);
    function VERSION() external pure returns (uint8 major, uint8 minor);
    function activate() external;
    function active() external view returns (bool);
    function burn() external;
    function changeKernel(address newKernel_) external;
    function claimDefaulted(address[] memory coolers_, uint256[] memory loans_) external;
    function configureDependencies() external returns (Keycode[] memory dependencies);
    function defund(address token_, uint256 amount_) external;
    function emergencyShutdown() external;
    function extendLoan(address cooler_, uint256 loanID_, uint8 times_) external;
    function factory() external view returns (address);
    function fundTime() external view returns (uint256);
    function getCollateralForLoan(uint256 principal_) external pure returns (uint256);
    function getLoanForCollateral(uint256 collateral_) external pure returns (uint256, uint256);
    function getTotalReceivables() external view returns (uint256);
    function gohm() external view returns (address);
    function interestForLoan(uint256 principal_, uint256 duration_) external pure returns (uint256);
    function interestReceivables() external view returns (uint256);
    function isActive() external view returns (bool);
    function isCoolerCallback() external pure returns (bool);
    function kernel() external view returns (address);
    function lendToCooler(address cooler_, uint256 amount_) external returns (uint256);
    function ohm() external view returns (address);
    function onDefault(uint256 loanID_, uint256 principle, uint256 interest, uint256 collateral) external;
    function onRepay(uint256 loanID_, uint256 principlePaid_, uint256 interestPaid_) external;
    function principalReceivables() external view returns (uint256);
    function rebalance() external returns (bool);
    function requestPermissions() external view returns (Permissions[] memory requests);
    function reserve() external view returns (address);
    function sReserve() external view returns (address);
    function staking() external view returns (address);
    function sweepIntoSavingsVault() external;
}
