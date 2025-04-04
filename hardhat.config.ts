import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomiclabs/hardhat-solhint";
import type { HardhatUserConfig } from "hardhat/config";

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.28",
		settings: {
			viaIR: true,
			optimizer: {
				enabled: true,
				runs: 10_000,
			},
			evmVersion: "cancun",
		},
	},
	networks: {
		hardhat: {
			hardfork: "cancun",
		},
		btp: {
			url: process.env.BTP_RPC_URL || "",
			gasPrice: process.env.BTP_GAS_PRICE
				? Number.parseInt(process.env.BTP_GAS_PRICE)
				: "auto",
		},
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_API_KEY,
	},
	sourcify: {
		enabled: true,
	},
};

export default config;
