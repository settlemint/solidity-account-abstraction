import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AccountAbstraction", (m) => {
	// Deploy EntryPoint first since accounts need it
	const entryPoint = m.contract("SmartEntryPoint", []);

	// Deploy factory with EntryPoint address as constructor parameter
	const smartAccountFactory = m.contract("SmartAccountFactory", [entryPoint]);

	return { entryPoint, smartAccountFactory };
});
