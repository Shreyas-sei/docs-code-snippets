import {
  ConnectButton,
  TransactionButton,
  useActiveAccount,
} from "thirdweb/react";
import {
  inAppWallet,
  smartWallet,
} from "thirdweb/wallets";
import { getContract, prepareContractCall, readContract } from "thirdweb";
import { defineChain } from "thirdweb/chains";
import { client } from "./client";
import { useState } from "react";

// ─── Sei chain config ─────────────────────────────────────────────────────────

const sei = defineChain(1329); // Sei mainnet chain ID

// ─── Wallets ──────────────────────────────────────────────────────────────────
// EIP-4337 Smart Wallet backed by an in-app wallet as the signer

const personalWallet = inAppWallet();

const wallet = smartWallet({
  chain: sei,
  gasless: true, // enable sponsored transactions
});

// ─── Contract ─────────────────────────────────────────────────────────────────
// Replace CONTRACT_ADDRESS with your deployed Storage contract on Sei

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

// ─── Storage Interaction ─────────────────────────────────────────────────────

function StorageInteraction() {
  const account = useActiveAccount();
  const [inputValue, setInputValue] = useState("");
  const [storedValue, setStoredValue] = useState<string | null>(null);
  const [isReading, setIsReading] = useState(false);

  const handleRead = async () => {
    setIsReading(true);
    try {
      const value = await readContract({
        contract: storageContract,
        method: "retrieve",
        params: [],
      });
      setStoredValue(value.toString());
    } finally {
      setIsReading(false);
    }
  };

  if (!account) {
    return <p>Connect your wallet to interact with the contract.</p>;
  }

  return (
    <div className="storage-interaction">
      <h2>Storage Contract</h2>
      <p>
        <strong>Smart Account:</strong> {account.address}
      </p>

      {/* Read */}
      <section>
        <h3>Read</h3>
        <button onClick={handleRead} disabled={isReading}>
          {isReading ? "Reading…" : "Retrieve value"}
        </button>
        {storedValue !== null && (
          <p>Stored value: <strong>{storedValue}</strong></p>
        )}
      </section>

      {/* Write */}
      <section>
        <h3>Write</h3>
        <input
          type="number"
          placeholder="Enter a number"
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
            alert("Value stored!");
            handleRead();
          }}
          disabled={!inputValue}
        >
          Store value
        </TransactionButton>
      </section>
    </div>
  );
}

// ─── App ──────────────────────────────────────────────────────────────────────

function App() {
  return (
    <div className="app">
      <h1>Thirdweb ERC-4337 Smart Wallet on Sei</h1>

      <ConnectButton
        client={client}
        wallets={[wallet]}
        walletConnect={{ projectId: "YOUR_WALLETCONNECT_PROJECT_ID" }}
        connectModal={{ size: "compact" }}
      />

      <StorageInteraction />
    </div>
  );
}

export default App;
