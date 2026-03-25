import {
  ConnectButton,
  TransactionButton,
  useActiveAccount,
  useActiveWallet,
} from "thirdweb/react";
import {
  inAppWallet,
} from "thirdweb/wallets";
import { getContract, prepareContractCall, readContract } from "thirdweb";
import { defineChain } from "thirdweb/chains";
import { client } from "./client";
import { useState } from "react";

// ─── Sei chain config ─────────────────────────────────────────────────────────

const sei = defineChain(1329); // Sei mainnet

// ─── Wallet: in-app wallet with EIP-7702 delegation ──────────────────────────
// EIP-7702 lets an EOA temporarily gain smart contract capabilities by delegating
// code to an implementation contract for the duration of a transaction.

const wallet = inAppWallet({
  executionMode: {
    mode: "EIP7702",
    sponsorGas: true,
  },
});

// ─── Contract ─────────────────────────────────────────────────────────────────

const CONTRACT_ADDRESS = "0xYourDeployedStorageContractAddress";

const storageContract = getContract({
  client,
  chain: sei,
  address: CONTRACT_ADDRESS,
  abi: [
    {
      name: "store",
      type: "function",
      inputs: [{ name: "num", type: "uint256" }],
      outputs: [],
      stateMutability: "nonpayable",
    },
    {
      name: "retrieve",
      type: "function",
      inputs: [],
      outputs: [{ name: "", type: "uint256" }],
      stateMutability: "view",
    },
  ],
});

// ─── Wallet Info ──────────────────────────────────────────────────────────────

function WalletInfo() {
  const account = useActiveAccount();
  const wallet = useActiveWallet();
  const [storedValue, setStoredValue] = useState<string | null>(null);
  const [inputValue, setInputValue] = useState("");

  const handleRead = async () => {
    const value = await readContract({
      contract: storageContract,
      method: "retrieve",
      params: [],
    });
    setStoredValue(value.toString());
  };

  if (!account) return null;

  return (
    <div className="wallet-info">
      <h2>EIP-7702 Wallet</h2>
      <p><strong>EOA (delegated):</strong> {account.address}</p>
      <p><strong>Wallet type:</strong> {wallet?.id}</p>

      <section>
        <h3>Read contract</h3>
        <button onClick={handleRead}>Retrieve stored value</button>
        {storedValue !== null && <p>Value: <strong>{storedValue}</strong></p>}
      </section>

      <section>
        <h3>Write contract (sponsored)</h3>
        <input
          type="number"
          placeholder="Number to store"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
        />
        <TransactionButton
          transaction={() =>
            prepareContractCall({
              contract: storageContract,
              method: "store",
              params: [BigInt(inputValue || "0")],
            })
          }
          onTransactionConfirmed={() => {
            alert("Stored!");
            handleRead();
          }}
        >
          Store value (gasless via EIP-7702)
        </TransactionButton>
      </section>
    </div>
  );
}

// ─── App ──────────────────────────────────────────────────────────────────────

function App() {
  return (
    <div className="app">
      <h1>Thirdweb EIP-7702 Wallet on Sei</h1>

      <ConnectButton
        client={client}
        wallets={[wallet]}
        connectModal={{ size: "compact" }}
      />

      <WalletInfo />
    </div>
  );
}

export default App;
