// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILoanConsolidator {
    type Keycode is bytes5;

    struct Permissions {
        Keycode keycode;
        bytes4 funcSelector;
    }

    error KernelAdapter_OnlyKernel(address caller_);
    error OnlyConsolidatorActive();
    error OnlyCoolerOwner();
    error OnlyLender();
    error OnlyPolicyActive();
    error OnlyThis();
    error Params_FeePercentageOutOfRange();
    error Params_InsufficientCoolerCount();
    error Params_InvalidAddress();
    error Params_InvalidClearinghouse();
    error Params_InvalidCooler();
    error Policy_ModuleDoesNotExist(Keycode keycode_);
    error Policy_WrongModuleVersion(bytes expected_);

    event ConsolidatorActivated();
    event ConsolidatorDeactivated();
    event FeePercentageSet(uint256 feePercentage);

    function ONE_HUNDRED_PERCENT() external view returns (uint256);
    function ROLES() external view returns (address);
    function ROLE_ADMIN() external view returns (bytes32);
    function ROLE_EMERGENCY_SHUTDOWN() external view returns (bytes32);
    function VERSION() external pure returns (uint256);
    function activate() external;
    function changeKernel(address newKernel_) external;
    function collateralRequired(address clearinghouse_, address cooler_, uint256[] memory ids_)
        external
        view
        returns (uint256 consolidatedLoanCollateral, uint256 existingLoanCollateral, uint256 additionalCollateral);
    function configureDependencies() external returns (Keycode[] memory dependencies);
    function consolidate(
        address clearinghouseFrom_,
        address clearinghouseTo_,
        address coolerFrom_,
        address coolerTo_,
        uint256[] memory ids_
    ) external;
    function consolidateWithNewOwner(
        address clearinghouseFrom_,
        address clearinghouseTo_,
        address coolerFrom_,
        address coolerTo_,
        uint256[] memory ids_
    ) external;
    function consolidatorActive() external view returns (bool);
    function deactivate() external;
    function feePercentage() external view returns (uint256);
    function fundsRequired(address clearinghouseTo_, address coolerFrom_, uint256[] memory ids_)
        external
        view
        returns (address reserveTo, uint256 interest, uint256 lenderFee, uint256 protocolFee);
    function getProtocolFee(uint256 totalDebt_) external view returns (uint256);
    function isActive() external view returns (bool);
    function kernel() external view returns (address);
    function onFlashLoan(address initiator_, address, uint256 amount_, uint256 lenderFee_, bytes memory params_)
        external
        returns (bytes32);
    function requestPermissions() external pure returns (Permissions[] memory requests);
    function requiredApprovals(address clearinghouseTo_, address coolerFrom_, uint256[] memory ids_)
        external
        view
        returns (address, uint256, address, uint256, uint256);
    function setFeePercentage(uint256 feePercentage_) external;
}
