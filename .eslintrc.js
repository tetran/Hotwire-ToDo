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
  ]
}