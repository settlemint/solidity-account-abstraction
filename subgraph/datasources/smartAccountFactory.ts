import type { AccountCreated } from "../../generated/SmartAccountFactory/SmartAccountFactory";
import {
	SmartAccount as SmartAccountEntity,
	SmartAccountFactory as SmartAccountFactoryEntity,
} from "../../generated/schema";
import { SmartAccount as SmartAccountTemplate } from "../../generated/templates";

export function handleAccountCreated(event: AccountCreated): void {
	let factory = SmartAccountFactoryEntity.load(event.address);
	if (!factory) {
		factory = new SmartAccountFactoryEntity(event.address);
		factory.save();
	}

	const account = new SmartAccountEntity(event.params.account);
	account.owner = event.params.owner;
	account.factory = factory.id;
	account.save();

	SmartAccountTemplate.create(event.params.account);
}
