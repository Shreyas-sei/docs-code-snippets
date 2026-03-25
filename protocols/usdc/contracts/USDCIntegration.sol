// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title USDCIntegration
 * @notice Demonstrates common USDC integration patterns on Sei EVM
 * @dev USDC on Sei is a standard ERC-20 token deployed by Circle.
 *      This contract shows safe patterns for accepting, holding, and distributing USDC.
 *
 * USDC Contract Addresses on Sei:
 *   Mainnet:  0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1
 *   Testnet:  Check config/addresses.json for current testnet address
 *
 * USDC has 6 decimals on all EVM chains.
 */

/// @dev Minimal IERC20 interface (sufficient for USDC integration)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @dev USDC-specific interface (includes minter/blacklist functions)
interface IFiatTokenV2 is IERC20 {
    function isBlacklisted(address account) external view returns (bool);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract USDCIntegration {
    // ─────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────

    IFiatTokenV2 public immutable usdc;

    /// @notice USDC decimals — always 6
    uint8 public constant USDC_DECIMALS = 6;

    /// @notice 1 USDC in raw units (10^6)
    uint256 public constant ONE_USDC = 1e6;

    address public owner;

    /// @notice User deposit balances in USDC raw units (6 decimals)
    mapping(address => uint256) public deposits;

    /// @notice Total USDC deposited across all users
    uint256 public totalDeposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event PaymentReceived(address indexed from, address indexed to, uint256 amount, bytes32 reference);

    modifier onlyOwner() {
        require(msg.sender == owner, "USDCIntegration: not owner");
        _;
    }

    // ─────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────

    /**
     * @param usdcAddress The USDC contract address on this network
     *                    Mainnet: 0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1
     */
    constructor(address usdcAddress) {
        require(usdcAddress != address(0), "USDCIntegration: zero address");
        usdc = IFiatTokenV2(usdcAddress);
        owner = msg.sender;
    }

    // ─────────────────────────────────────────────
    // Pattern 1: User deposits using approve + transferFrom
    // ─────────────────────────────────────────────

    /**
     * @notice Deposit USDC using the standard approve + transferFrom pattern
     * @dev User must call usdc.approve(address(this), amount) before calling this
     * @param amount Amount of USDC to deposit (6 decimal units, e.g. 1000000 = $1.00)
     *
     * Frontend flow:
     *   1. await usdc.approve(contractAddress, amount)
     *   2. await contract.deposit(amount)
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "USDCIntegration: amount must be > 0");
        require(!usdc.isBlacklisted(msg.sender), "USDCIntegration: sender is blacklisted");

        bool success = usdc.transferFrom(msg.sender, address(this), amount);
        require(success, "USDCIntegration: transferFrom failed");

        deposits[msg.sender] += amount;
        totalDeposits += amount;

        emit Deposited(msg.sender, amount);
    }

    // ─────────────────────────────────────────────
    // Pattern 2: Permit (EIP-2612) gasless approval
    // ─────────────────────────────────────────────

    /**
     * @notice Deposit USDC using EIP-2612 permit (single transaction, no pre-approval needed)
     * @dev USDC supports permit on most chains. Obtain signature from the user off-chain.
     * @param amount   Amount to deposit (6 decimals)
     * @param deadline Permit expiry timestamp
     * @param v,r,s    EIP-2612 signature components
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount > 0, "USDCIntegration: amount must be > 0");

        // Call permit to set the allowance in a single transaction
        // This requires USDC to implement IERC20Permit — true for Circle USDC
        (bool permitSuccess, ) = address(usdc).call(
            abi.encodeWithSignature(
                "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)",
                msg.sender,
                address(this),
                amount,
                deadline,
                v,
                r,
                s
            )
        );
        require(permitSuccess, "USDCIntegration: permit failed");

        bool success = usdc.transferFrom(msg.sender, address(this), amount);
        require(success, "USDCIntegration: transferFrom failed");

        deposits[msg.sender] += amount;
        totalDeposits += amount;

        emit Deposited(msg.sender, amount);
    }

    // ─────────────────────────────────────────────
    // Pattern 3: Withdraw
    // ─────────────────────────────────────────────

    /**
     * @notice Withdraw previously deposited USDC
     * @param amount Amount to withdraw (6 decimal units)
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "USDCIntegration: amount must be > 0");
        require(deposits[msg.sender] >= amount, "USDCIntegration: insufficient balance");

        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        bool success = usdc.transfer(msg.sender, amount);
        require(success, "USDCIntegration: transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // ─────────────────────────────────────────────
    // Pattern 4: Direct payment with reference
    // ─────────────────────────────────────────────

    /**
     * @notice Accept a direct USDC payment from one address to another, with a reference ID
     * @dev The payer must approve this contract first
     * @param to        Recipient address
     * @param amount    Payment amount (6 decimals)
     * @param reference Payment reference (e.g. invoice ID, order ID)
     */
    function pay(
        address to,
        uint256 amount,
        bytes32 reference
    ) external {
        require(to != address(0), "USDCIntegration: zero recipient");
        require(amount > 0, "USDCIntegration: amount must be > 0");
        require(!usdc.isBlacklisted(msg.sender), "USDCIntegration: sender blacklisted");
        require(!usdc.isBlacklisted(to), "USDCIntegration: recipient blacklisted");

        bool success = usdc.transferFrom(msg.sender, to, amount);
        require(success, "USDCIntegration: payment failed");

        emit PaymentReceived(msg.sender, to, amount, reference);
    }

    // ─────────────────────────────────────────────
    // View helpers
    // ─────────────────────────────────────────────

    /**
     * @notice Returns the USDC balance of this contract
     */
    function contractBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    /**
     * @notice Returns the user's deposited balance, formatted as a human-readable amount
     * @return rawAmount   Raw USDC units (6 decimals)
     * @return usdDollars  Dollar amount (rawAmount / 1e6)
     * @return usdCents    Remaining cents
     */
    function getDepositFormatted(address user)
        external
        view
        returns (
            uint256 rawAmount,
            uint256 usdDollars,
            uint256 usdCents
        )
    {
        rawAmount = deposits[user];
        usdDollars = rawAmount / ONE_USDC;
        usdCents = (rawAmount % ONE_USDC) / (ONE_USDC / 100);
    }

    /**
     * @notice Checks whether the given address is blacklisted by Circle
     */
    function isBlacklisted(address account) external view returns (bool) {
        return usdc.isBlacklisted(account);
    }

    /**
     * @notice Converts a human-readable dollar amount to raw USDC units
     * @param dollars Dollar amount (e.g. 100 for $100.00)
     */
    function toUSDCUnits(uint256 dollars) external pure returns (uint256) {
        return dollars * ONE_USDC;
    }

    // ─────────────────────────────────────────────
    // Owner emergency functions
    // ─────────────────────────────────────────────

    /**
     * @notice Emergency withdrawal by owner (use with caution — add timelocks in production)
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "USDCIntegration: zero address");
        bool success = usdc.transfer(to, amount);
        require(success, "USDCIntegration: emergency withdraw failed");
    }
}
