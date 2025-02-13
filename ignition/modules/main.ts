import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AccountAbstraction", (m) => {
	// Deploy EntryPoint first since accounts need it
	const entryPoint = m.contract("SmartAccountEntryPoint", []);

	// Deploy factory that will use this EntryPoint
	const smartAccountFactory = m.contract("SmartAccountFactory", []);

	return { entryPoint, smartAccountFactory };
});
