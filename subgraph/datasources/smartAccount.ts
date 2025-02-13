import {
	SmartAccount as SmartAccountEntity,
	SmartAccountFactory as SmartAccountFactoryEntity,
	SmartAccountTransaction,
} from "../../generated/schema";

import type { TransactionExecuted } from "../../generated/templates/SmartAccount/SmartAccount";

export function handleTransactionExecuted(event: TransactionExecuted): void {
	const txId = event.transaction.hash.toHexString();
	const tx = new SmartAccountTransaction(txId);
	tx.account = event.address;
	tx.target = event.params.target;
	tx.value = event.params.value;
	tx.data = event.params.data;
	tx.timestamp = event.block.timestamp;
	tx.save();
}
