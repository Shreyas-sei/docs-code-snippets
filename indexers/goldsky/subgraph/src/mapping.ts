import { BigInt, Bytes, Address, log } from "@graphprotocol/graph-ts";
import {
  Transfer as TransferEvent,
  Approval as ApprovalEvent,
  ERC20,
} from "../../generated/ERC20Token/ERC20";
import {
  Token,
  Account,
  AccountBalance,
  Transfer,
  Approval,
} from "../../generated/schema";

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

function getOrCreateToken(address: Address): Token {
  let token = Token.load(address.toHexString());
  if (token == null) {
    const contract = ERC20.bind(address);
    token = new Token(address.toHexString());

    const nameResult = contract.try_name();
    token.name = nameResult.reverted ? "Unknown" : nameResult.value;

    const symbolResult = contract.try_symbol();
    token.symbol = symbolResult.reverted ? "???" : symbolResult.value;

    const decimalsResult = contract.try_decimals();
    token.decimals = decimalsResult.reverted ? 18 : decimalsResult.value;

    const totalSupplyResult = contract.try_totalSupply();
    token.totalSupply = totalSupplyResult.reverted
      ? BigInt.fromI32(0)
      : totalSupplyResult.value;

    token.transferCount = BigInt.fromI32(0);
    token.holderCount = BigInt.fromI32(0);
    token.save();
  }
  return token as Token;
}

function getOrCreateAccount(address: Address): Account {
  const id = address.toHexString();
  let account = Account.load(id);
  if (account == null) {
    account = new Account(id);
    account.save();
  }
  return account as Account;
}

function getOrCreateBalance(
  token: Token,
  account: Account,
  blockNumber: BigInt,
  timestamp: BigInt
): AccountBalance {
  const id = token.id + "-" + account.id;
  let balance = AccountBalance.load(id);
  if (balance == null) {
    balance = new AccountBalance(id);
    balance.token = token.id;
    balance.account = account.id;
    balance.amount = BigInt.fromI32(0);
    balance.blockNumber = blockNumber;
    balance.timestamp = timestamp;
    balance.save();
  }
  return balance as AccountBalance;
}

// ─────────────────────────────────────────────
// Event handlers
// ─────────────────────────────────────────────

export function handleTransfer(event: TransferEvent): void {
  const tokenAddress = event.address;
  const token = getOrCreateToken(tokenAddress);
  const from = getOrCreateAccount(event.params.from);
  const to = getOrCreateAccount(event.params.to);
  const amount = event.params.value;

  // ── Update balances ──────────────────────────────────────────────
  const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

  if (from.id != ZERO_ADDRESS) {
    const fromBalance = getOrCreateBalance(
      token,
      from,
      event.block.number,
      event.block.timestamp
    );
    fromBalance.amount = fromBalance.amount.minus(amount);
    fromBalance.blockNumber = event.block.number;
    fromBalance.timestamp = event.block.timestamp;
    fromBalance.save();
  }

  if (to.id != ZERO_ADDRESS) {
    const toBalance = getOrCreateBalance(
      token,
      to,
      event.block.number,
      event.block.timestamp
    );
    const wasZero = toBalance.amount.equals(BigInt.fromI32(0));
    toBalance.amount = toBalance.amount.plus(amount);
    toBalance.blockNumber = event.block.number;
    toBalance.timestamp = event.block.timestamp;
    toBalance.save();

    // Track new holders
    if (wasZero && toBalance.amount.gt(BigInt.fromI32(0))) {
      token.holderCount = token.holderCount.plus(BigInt.fromI32(1));
    }
  }

  // ── Update token stats ───────────────────────────────────────────
  token.transferCount = token.transferCount.plus(BigInt.fromI32(1));
  token.save();

  // ── Store Transfer entity ────────────────────────────────────────
  const transferId =
    event.transaction.hash.toHexString() +
    "-" +
    event.logIndex.toString();

  const transfer = new Transfer(transferId);
  transfer.token = token.id;
  transfer.from = from.id;
  transfer.to = to.id;
  transfer.amount = amount;
  transfer.blockNumber = event.block.number;
  transfer.blockTimestamp = event.block.timestamp;
  transfer.transactionHash = event.transaction.hash;
  transfer.logIndex = event.logIndex;
  transfer.save();

  log.info("Transfer: {} -> {} amount={}", [
    from.id,
    to.id,
    amount.toString(),
  ]);
}

export function handleApproval(event: ApprovalEvent): void {
  const tokenAddress = event.address;
  const token = getOrCreateToken(tokenAddress);
  const owner = getOrCreateAccount(event.params.owner);
  const spender = getOrCreateAccount(event.params.spender);

  const approvalId =
    event.transaction.hash.toHexString() +
    "-" +
    event.logIndex.toString();

  const approval = new Approval(approvalId);
  approval.token = token.id;
  approval.owner = owner.id;
  approval.spender = spender.id;
  approval.amount = event.params.value;
  approval.blockNumber = event.block.number;
  approval.blockTimestamp = event.block.timestamp;
  approval.transactionHash = event.transaction.hash;
  approval.save();
}
