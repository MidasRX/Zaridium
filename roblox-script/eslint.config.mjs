import js from "@eslint/js";
import prettier from "eslint-plugin-prettier/recommended";
import robloxTs from "eslint-plugin-roblox-ts";
import tseslint from "typescript-eslint";

export default tseslint.config(
	{ ignores: ["out/**", "include/**", "node_modules/**", "public/**"] },
	js.configs.recommended,
	...tseslint.configs.recommended,
	robloxTs.configs.recommended,
	prettier,
	{
		files: ["src/**/*.{ts,tsx}"],
		languageOptions: {
			parserOptions: {
				jsx: true,
				useJSXTextNode: true,
			},
		},
		rules: {
			"prettier/prettier": "warn",
			"roblox-ts/no-namespace-merging": "off",
		},
	},
);