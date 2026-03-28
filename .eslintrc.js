module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true
  },
  extends: [
    'standard'
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  rules: {
    // カスタムルール
    'no-console': 'warn',
    'no-unused-vars': ['error', { 'argsIgnorePattern': '^_' }],
    'prefer-const': 'error',
    'no-var': 'error',
    
    // Stimulusコントローラー用の設定
    'camelcase': ['error', { 'allow': ['connect', 'disconnect'] }]
  },
  globals: {
    // Stimulusとホットワイヤー関連のグローバル変数
    'Stimulus': 'readonly',
    'Turbo': 'readonly',
    'application': 'readonly'
  },
  ignorePatterns: [
    'node_modules/',
    'vendor/',
    'tmp/',
    'log/',
    'storage/',
    'public/',
    '**/*.min.js'
  ],
  overrides: [
    {
      files: ['*.ts', '*.tsx'],
      parser: '@typescript-eslint/parser',
      extends: [
        'standard',
        'plugin:@typescript-eslint/recommended'
      ],
      rules: {
        'no-console': 'warn',
        'no-unused-vars': 'off',
        '@typescript-eslint/no-unused-vars': ['error', { 'argsIgnorePattern': '^_' }],
        'prefer-const': 'error',
        'no-var': 'error',
        // API応答のsnake_caseフィールドを許可
        'camelcase': 'off',
        // React/TSの一般的なスタイルに合わせる
        'comma-dangle': 'off',
        'space-before-function-paren': 'off',
        'multiline-ternary': 'off'
      }
    }
  ]
}