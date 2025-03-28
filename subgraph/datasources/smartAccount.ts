import {
	SmartAccount as SmartAccountEntity,
	SmartAccountFactory as SmartAccountFactoryEntity,
	SmartAccountTransaction,
} from "../../generated/schema";

import type {
	SmartAccountInitialized,
	TransactionExecuted,
} from "../../generated/templates/SmartAccount/SmartAccount";

export function handleAccountInitialized(event: SmartAccountInitialized): void {
	const accountId = event.address.toHexString();
	const account = new SmartAccountEntity(accountId);

	account.owner = event.params.owner;
	account.factory = event.transaction.from.toHexString(); // factory address that deployed the account
	account.createdAt = event.block.timestamp;
	account.transactions = [];

	account.save();
}

export function handleTransactionExecuted(event: TransactionExecuted): void {
	const txId = event.transaction.hash.toHexString();
	const accountId = event.address.toHexString();

	// Create transaction entity
	const tx = new SmartAccountTransaction(txId);
	tx.account = accountId;
	tx.target = event.params.target;
	tx.value = event.params.value;
	tx.data = event.params.data;
	tx.timestamp = event.block.timestamp;
	tx.blockNumber = event.block.number;
	tx.transactionHash = event.transaction.hash;
	tx.save();

	// Update account's transactions array
	const account = SmartAccountEntity.load(accountId);
	if (account) {
		const transactions = account.transactions;
		transactions.push(txId);
		account.transactions = transactions;
		account.save();
	}
}
