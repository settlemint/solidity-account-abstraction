import { BigInt as BigIntType } from "@graphprotocol/graph-ts";
import type { AccountCreated } from "../../generated/SmartAccountFactory/SmartAccountFactory";
import {
	SmartAccount as SmartAccountEntity,
	SmartAccountFactory as SmartAccountFactoryEntity,
} from "../../generated/schema";
import { SmartAccount } from "../../generated/templates";

export function handleAccountCreated(event: AccountCreated): void {
	// Convert Address to string for entity IDs
	let factory = SmartAccountFactoryEntity.load(event.address.toHexString());
	if (!factory) {
		factory = new SmartAccountFactoryEntity(event.address.toHexString());
		factory.totalAccounts = BigIntType.fromI32(0);
		factory.save();
	}

	const account = new SmartAccountEntity(event.params.account.toHexString());
	account.owner = event.params.owner;
	account.factory = factory.id;
	account.createdAt = event.block.timestamp;
	account.save();

	// Increment total accounts
	factory.totalAccounts = factory.totalAccounts.plus(BigIntType.fromI32(1));
	factory.save();

	// Create the template instance using DataSourceTemplate
	SmartAccount.create(event.params.account);
}
