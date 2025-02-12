import { BigInt } from "@graphprotocol/graph-ts";
import type { AccountCreated } from "../generated/SmartAccountFactory/SmartAccountFactory";
import {
	SmartAccount,
	SmartAccountFactory as SmartAccountFactoryEntity,
	SmartAccountTransaction,
} from "../generated/schema";
import { SmartAccount as SmartAccountTemplate } from "../generated/templates";
import type { TransactionExecuted } from "../generated/templates/SmartAccount/SmartAccount";

export function handleAccountCreated(event: AccountCreated): void {
	let factory = SmartAccountFactoryEntity.load(event.address.toHexString());
	if (!factory) {
		factory = new SmartAccountFactoryEntity(event.address.toHexString());
		factory.totalAccounts = BigInt.fromI32(0);
	}
	factory.totalAccounts = factory.totalAccounts.plus(BigInt.fromI32(1));
	factory.save();

	const account = new SmartAccount(event.params.account.toHexString());
	account.owner = event.params.owner;
	account.createdAt = event.block.timestamp;
	account.factory = factory.id;
	account.save();

	// Start indexing the new account
	SmartAccountTemplate.create(event.params.account);
}

export function handleTransactionExecuted(event: TransactionExecuted): void {
	const txId = event.transaction.hash.toHexString();
	const tx = new SmartAccountTransaction(txId);
	tx.account = event.address.toHexString();
	tx.target = event.params.target;
	tx.value = event.params.value;
	tx.data = event.params.data;
	tx.timestamp = event.block.timestamp;
	tx.success = true;
	tx.save();
}
