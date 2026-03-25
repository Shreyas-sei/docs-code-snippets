import { useState } from "react";
import { PayEmbed, useActiveAccount } from "thirdweb/react";
import { defineChain } from "thirdweb/chains";
import { getContract } from "thirdweb";
import { client } from "./client";

// ─── Chains ───────────────────────────────────────────────────────────────────

const sei = defineChain(1329);      // Sei mainnet
const ethereum = defineChain(1);    // Ethereum mainnet
const arbitrum = defineChain(42161);

// ─── Supported chains for the bridge ─────────────────────────────────────────

const SUPPORTED_CHAINS = [sei, ethereum, arbitrum];

// ─── Token address on Sei (USDC example) ─────────────────────────────────────
// Native SEI = undefined (use null/undefined for native)
// USDC on Sei: verify at https://docs.sei.io/evm/token-list

const SEI_USDC_ADDRESS = "0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F";

// ─── BridgeComponent ─────────────────────────────────────────────────────────

export function BridgeComponent() {
  const account = useActiveAccount();
  const [bridgeMode, setBridgeMode] = useState<"buy" | "bridge">("bridge");

  if (!account) {
    return <p>Connect your wallet to use the bridge.</p>;
  }

  return (
    <div className="bridge-component">
      <h2>Bridge to Sei</h2>

      <div className="mode-toggle">
        <button
          onClick={() => setBridgeMode("buy")}
          className={bridgeMode === "buy" ? "active" : ""}
        >
          Buy
        </button>
        <button
          onClick={() => setBridgeMode("bridge")}
          className={bridgeMode === "bridge" ? "active" : ""}
        >
          Bridge
        </button>
      </div>

      {/* thirdweb PayEmbed handles token purchases and cross-chain bridging */}
      <PayEmbed
        client={client}
        payOptions={{
          mode: bridgeMode,
          // Bridge to Sei native SEI
          destination: {
            chain: sei,
            // For native SEI: omit token (or set to undefined)
            // For USDC on Sei: uncomment below
            // token: {
            //   address: SEI_USDC_ADDRESS,
            //   symbol: "USDC",
            //   name: "USD Coin",
            //   decimals: 6,
            // },
          },
        }}
        style={{ width: "100%", maxWidth: "480px" }}
      />

      <p className="note">
        Powered by thirdweb Universal Bridge — supports 350+ chains and 20,000+ tokens.
        <br />
        <a
          href="https://docs.sei.io/evm/bridging/thirdweb"
          target="_blank"
          rel="noreferrer"
        >
          Sei bridge docs
        </a>
      </p>
    </div>
  );
}
