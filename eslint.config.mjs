import { defineConfig } from "eslint/config";

const commonRules = {
  curly: ["error", "all"],
  eqeqeq: ["error", "always"],
  "no-console": "off",
  "no-unused-vars": [
    "warn",
    {
      argsIgnorePattern: "^_",
      caughtErrorsIgnorePattern: "^_",
    },
  ],
  "no-var": "error",
  "object-shorthand": ["error", "always"],
  "prefer-const": [
    "error",
    {
      destructuring: "all",
    },
  ],
};

export default defineConfig([
  {
    name: "global-ignores",
    ignores: [
      "**/node_modules/**",
      "**/dist/**",
      "**/build/**",
      "**/coverage/**",
      "**/.next/**",
      "**/.nuxt/**",
      "**/.output/**",
    ],
  },
  {
    name: "javascript-modules",
    files: ["**/*.{js,mjs,jsx}"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
      },
      globals: {
        console: "readonly",
        process: "readonly",
      },
    },
    linterOptions: {
      reportUnusedDisableDirectives: "warn",
    },
    rules: commonRules,
  },
  {
    name: "javascript-commonjs",
    files: ["**/*.cjs"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "commonjs",
      globals: {
        __dirname: "readonly",
        __filename: "readonly",
        console: "readonly",
        module: "readonly",
        process: "readonly",
        require: "readonly",
      },
    },
    linterOptions: {
      reportUnusedDisableDirectives: "warn",
    },
    rules: commonRules,
  },
]);
