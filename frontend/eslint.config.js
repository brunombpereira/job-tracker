// Minimal flat config (ESLint 9)
import js from "@eslint/js";
import tsParser from "@typescript-eslint/parser";
import tsPlugin from "@typescript-eslint/eslint-plugin";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";

const browserGlobals = {
  window: "readonly",
  document: "readonly",
  console: "readonly",
  fetch: "readonly",
  setTimeout: "readonly",
  clearTimeout: "readonly",
  setInterval: "readonly",
  clearInterval: "readonly",
  localStorage: "readonly",
  sessionStorage: "readonly",
  navigator: "readonly",
  location: "readonly",
  HTMLElement: "readonly",
  HTMLInputElement: "readonly",
  HTMLButtonElement: "readonly",
  HTMLDivElement: "readonly",
  Event: "readonly",
  KeyboardEvent: "readonly",
  MouseEvent: "readonly",
  confirm: "readonly",
  alert: "readonly",
  prompt: "readonly",
  URL: "readonly",
  URLSearchParams: "readonly",
};

const nodeGlobals = {
  __dirname: "readonly",
  __filename: "readonly",
  process: "readonly",
  module: "readonly",
  require: "readonly",
  Buffer: "readonly",
};

export default [
  js.configs.recommended,
  {
    files: ["src/**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: { ecmaVersion: "latest", sourceType: "module", ecmaFeatures: { jsx: true } },
      globals: browserGlobals,
    },
    plugins: { "@typescript-eslint": tsPlugin, "react-hooks": reactHooks, "react-refresh": reactRefresh },
    rules: {
      ...reactHooks.configs.recommended.rules,
      "react-refresh/only-export-components": ["warn", { allowConstantExport: true }],
      // Disable base no-unused-vars in favour of the TS-aware one — base
      // flags TS type-position parameter names like `(filters: T) => void`.
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": [
        "warn",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
    },
  },
  {
    files: ["*.config.{ts,js}", "vite.config.ts"],
    languageOptions: {
      parser: tsParser,
      parserOptions: { ecmaVersion: "latest", sourceType: "module" },
      globals: nodeGlobals,
    },
    plugins: { "@typescript-eslint": tsPlugin },
  },
  { ignores: ["dist/", "node_modules/", "**/*.d.ts", "vite.config.d.ts", "vite.config.js"] },
];
