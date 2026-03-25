// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Api3Consumer
 * @notice Reads price data from API3 dAPIs (decentralised APIs) on Sei EVM
 * @dev API3 dAPIs are self-funded or managed data feeds backed by first-party oracles.
 *      Each dAPI name maps to a data feed on the API3 proxy contract.
 *
 * API3 Proxy address on Sei:
 *   Mainnet:  Check https://docs.api3.org/reference/dapis/understand/proxy-contracts.html
 *   Testnet:  Check https://docs.api3.org/reference/dapis/understand/proxy-contracts.html
 *
 * How to get a proxy address for a specific dAPI:
 *   1. Visit https://market.api3.org
 *   2. Select "Sei" network and choose a data feed (e.g. SEI/USD)
 *   3. Deploy/activate the proxy and copy its address
 *
 * The proxy interface exposes a single function: read() -> (value, timestamp)
 */

/// @dev Minimal interface for an API3 dAPI proxy
interface IApi3DapiProxy {
    /**
     * @notice Reads the latest value from the dAPI
     * @return value     Signed 224-bit fixed-point number (18 decimals)
     * @return timestamp Unix timestamp of the most recent data point
     */
    function read() external view returns (int224 value, uint32 timestamp);
}

contract Api3Consumer {
    // ─────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────

    /// @notice Mapping from a human-readable name to its dAPI proxy address
    mapping(string => address) public proxies;

    /// @notice Owner for proxy management (simplified — no full Ownable for brevity)
    address public immutable owner;

    event ProxyRegistered(string indexed name, address indexed proxy);
    event ProxyUpdated(string indexed name, address indexed oldProxy, address indexed newProxy);

    modifier onlyOwner() {
        require(msg.sender == owner, "Api3Consumer: not owner");
        _;
    }

    // ─────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────

    /**
     * @param proxyNames   Array of human-readable dAPI names (e.g. ["SEI/USD", "ETH/USD"])
     * @param proxyAddrs   Corresponding proxy contract addresses
     */
    constructor(string[] memory proxyNames, address[] memory proxyAddrs) {
        require(proxyNames.length == proxyAddrs.length, "Api3Consumer: length mismatch");
        owner = msg.sender;
        for (uint256 i = 0; i < proxyNames.length; i++) {
            require(proxyAddrs[i] != address(0), "Api3Consumer: zero address");
            proxies[proxyNames[i]] = proxyAddrs[i];
            emit ProxyRegistered(proxyNames[i], proxyAddrs[i]);
        }
    }

    // ─────────────────────────────────────────────
    // Reading dAPI prices
    // ─────────────────────────────────────────────

    /**
     * @notice Reads the latest value for a registered dAPI
     * @param name The human-readable dAPI name (e.g. "SEI/USD")
     * @return value     Price as int224 with 18 decimals
     * @return timestamp Unix timestamp of the latest update
     */
    function readDapi(string calldata name)
        public
        view
        returns (int224 value, uint32 timestamp)
    {
        address proxy = proxies[name];
        require(proxy != address(0), "Api3Consumer: dAPI not registered");
        return IApi3DapiProxy(proxy).read();
    }

    /**
     * @notice Reads a dAPI directly from a proxy address (without registration)
     * @param proxyAddress The dAPI proxy contract address
     */
    function readDapiFromProxy(address proxyAddress)
        public
        view
        returns (int224 value, uint32 timestamp)
    {
        require(proxyAddress != address(0), "Api3Consumer: zero address");
        return IApi3DapiProxy(proxyAddress).read();
    }

    /**
     * @notice Returns the price as uint256 with 18 decimals (reverts if negative)
     * @param name The human-readable dAPI name
     */
    function getPriceUint256(string calldata name) external view returns (uint256) {
        (int224 value, ) = readDapi(name);
        require(value > 0, "Api3Consumer: non-positive price");
        return uint256(int256(value));
    }

    /**
     * @notice Returns the price with a staleness check
     * @param name      The human-readable dAPI name
     * @param maxAge    Maximum acceptable age in seconds
     */
    function getPriceWithStalenessCheck(string calldata name, uint256 maxAge)
        external
        view
        returns (int224 value, uint32 timestamp)
    {
        (value, timestamp) = readDapi(name);
        require(value > 0, "Api3Consumer: non-positive price");
        require(
            block.timestamp - uint256(timestamp) <= maxAge,
            "Api3Consumer: price too stale"
        );
    }

    /**
     * @notice Reads multiple dAPIs in a single call
     * @param names Array of dAPI names
     * @return values     Array of prices (18 decimals each)
     * @return timestamps Array of update timestamps
     */
    function readMultiple(string[] calldata names)
        external
        view
        returns (int224[] memory values, uint32[] memory timestamps)
    {
        values = new int224[](names.length);
        timestamps = new uint32[](names.length);
        for (uint256 i = 0; i < names.length; i++) {
            (values[i], timestamps[i]) = readDapi(names[i]);
        }
    }

    // ─────────────────────────────────────────────
    // Proxy management
    // ─────────────────────────────────────────────

    /**
     * @notice Registers or updates a dAPI proxy address
     */
    function setProxy(string calldata name, address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Api3Consumer: zero address");
        address old = proxies[name];
        proxies[name] = proxyAddress;
        if (old == address(0)) {
            emit ProxyRegistered(name, proxyAddress);
        } else {
            emit ProxyUpdated(name, old, proxyAddress);
        }
    }
}
