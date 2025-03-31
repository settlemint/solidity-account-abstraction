import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("AccountAbstraction", (m) => {
	const entryPoint = m.contract("SmartEntryPoint", []);
	const smartAccountFactory = m.contract("SmartAccountFactory", [entryPoint]);
	const paymaster = m.contract("UnrestrictedPaymaster", [entryPoint]);

	return { entryPoint, smartAccountFactory, paymaster };
});
