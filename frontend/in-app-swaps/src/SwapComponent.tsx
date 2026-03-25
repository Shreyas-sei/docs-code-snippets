import { useState } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt, useBalance } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';

// ─── Types ────────────────────────────────────────────────────────────────────

interface Token {
  symbol: string;
  address: `0x${string}` | 'native';
  decimals: number;
  name: string;
}

// ─── Sei tokens ──────────────────────────────────────────────────────────────

const SEI_TOKENS: Token[] = [
  {
    symbol: 'SEI',
    address: 'native',
    decimals: 18,
    name: 'Sei',
  },
  {
    // USDC on Sei mainnet — verify current address at https://docs.sei.io/evm/token-list
    symbol: 'USDC',
    address: '0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F',
    decimals: 6,
    name: 'USD Coin',
  },
  {
    // WSEI — wrapped SEI
    symbol: 'WSEI',
    address: '0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7',
    decimals: 18,
    name: 'Wrapped SEI',
  },
];

// ─── Minimal ERC-20 ABI for approve ──────────────────────────────────────────

const ERC20_APPROVE_ABI = [
  {
    name: 'approve',
    type: 'function',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
  },
] as const;

// ─── Component ────────────────────────────────────────────────────────────────

export function SwapComponent() {
  const { address, isConnected } = useAccount();
  const [tokenIn, setTokenIn] = useState<Token>(SEI_TOKENS[0]);
  const [tokenOut, setTokenOut] = useState<Token>(SEI_TOKENS[1]);
  const [amountIn, setAmountIn] = useState('');

  const { data: balanceData } = useBalance({
    address,
    token: tokenIn.address === 'native' ? undefined : tokenIn.address,
  });

  const { writeContract, data: txHash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash: txHash });

  const handleSwapTokens = () => {
    setTokenIn(tokenOut);
    setTokenOut(tokenIn);
    setAmountIn('');
  };

  // Example: approve the DEX router to spend `tokenIn`
  // In a real integration replace ROUTER_ADDRESS with the DEX router deployed on Sei
  const ROUTER_ADDRESS = '0xYourDexRouterAddress' as `0x${string}`;

  const handleApprove = () => {
    if (!amountIn || tokenIn.address === 'native') return;
    writeContract({
      address: tokenIn.address,
      abi: ERC20_APPROVE_ABI,
      functionName: 'approve',
      args: [ROUTER_ADDRESS, parseUnits(amountIn, tokenIn.decimals)],
    });
  };

  if (!isConnected) {
    return <p>Connect your wallet to use the swap.</p>;
  }

  return (
    <div className="swap-component">
      <h2>Swap Tokens</h2>

      {/* Token In */}
      <div className="swap-row">
        <label>From</label>
        <select
          value={tokenIn.symbol}
          onChange={(e) => {
            const t = SEI_TOKENS.find((t) => t.symbol === e.target.value)!;
            setTokenIn(t);
          }}
        >
          {SEI_TOKENS.map((t) => (
            <option key={t.symbol} value={t.symbol}>
              {t.symbol}
            </option>
          ))}
        </select>
        <input
          type="number"
          placeholder="0.0"
          value={amountIn}
          onChange={(e) => setAmountIn(e.target.value)}
        />
        <p className="balance">
          Balance:{' '}
          {balanceData
            ? `${formatUnits(balanceData.value, balanceData.decimals)} ${balanceData.symbol}`
            : '—'}
        </p>
      </div>

      {/* Swap direction button */}
      <button className="swap-direction" onClick={handleSwapTokens}>
        ↕
      </button>

      {/* Token Out */}
      <div className="swap-row">
        <label>To</label>
        <select
          value={tokenOut.symbol}
          onChange={(e) => {
            const t = SEI_TOKENS.find((t) => t.symbol === e.target.value)!;
            setTokenOut(t);
          }}
        >
          {SEI_TOKENS.map((t) => (
            <option key={t.symbol} value={t.symbol}>
              {t.symbol}
            </option>
          ))}
        </select>
      </div>

      {/* Approve (required before swap for ERC-20 tokenIn) */}
      {tokenIn.address !== 'native' && (
        <button onClick={handleApprove} disabled={isPending || isConfirming || !amountIn}>
          {isPending ? 'Confirm in wallet…' : isConfirming ? 'Confirming…' : `Approve ${tokenIn.symbol}`}
        </button>
      )}

      {txHash && (
        <p>
          Tx:{' '}
          <a href={`https://seitrace.com/tx/${txHash}`} target="_blank" rel="noreferrer">
            {txHash}
          </a>
        </p>
      )}
      {isSuccess && <p>Approval confirmed. You can now swap.</p>}

      <p className="note">
        Note: Connect this component to a DEX router (e.g. DragonSwap) by replacing{' '}
        <code>ROUTER_ADDRESS</code> and calling the router's swap function after approval.
      </p>
    </div>
  );
}
