import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DEFAULT_PAYMASTER_STAKE = BigInt("1e17"); // 0.1 ETH
const DEFAULT_UNSTAKE_DELAY_SEC = 60 * 60 * 24 * 2; // 2 days

export default buildModule("AccountAbstraction", (m) => {
	const entryPoint = m.contract("SmartAccountEntryPoint", [
		DEFAULT_PAYMASTER_STAKE,
		DEFAULT_UNSTAKE_DELAY_SEC,
	]);
	const smartAccountFactory = m.contract("SmartAccountFactory", []);

	return { entryPoint, smartAccountFactory };
});
