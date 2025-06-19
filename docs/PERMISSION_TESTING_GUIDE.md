# 権限テスト実装ガイド

## 概要

このドキュメントでは、管理者機能およびロールベース権限システムのテスト実装方法について説明します。

## 基本的なテスト構造

### 1. テストの基本パターン

権限テストは以下の4つのカテゴリーに分類されます：

```ruby
class Admin::ExampleControllerTest < ActionDispatch::IntegrationTest
  # 1. 認証テスト - ログインが必要
  # 2. 基本認可テスト - 管理者権限が必要  
  # 3. 機能別権限テスト - 具体的な権限が必要
  # 4. 正常系テスト - 適切な権限での動作確認
end
```

### 2. テストヘルパーメソッド

`test/test_helper.rb` で定義されている便利なメソッド：

```ruby
# ログイン関連
login_as(user)                # 指定ユーザーでログイン
login_as_admin                # 管理者でログイン
login_as_user_manager         # ユーザー管理者でログイン
login_as_regular_user         # 一般ユーザーでログイン

# アサーション関連
assert_admin_access_required  # 管理者権限が必要であることを確認
```

## 権限テストの実装パターン

### 1. 認証テスト

```ruby
test "should redirect to login when not authenticated" do
  get admin_example_path
  assert_redirected_to login_path
end
```

### 2. 基本管理者権限テスト

```ruby
test "should deny access to users without admin permissions" do
  login_as(users(:no_role_user))
  get admin_example_path
  assert_admin_access_required
end
```

### 3. 詳細権限テスト

#### 読み取り権限テスト

```ruby
test "should require Resource:read permission for show action" do
  # 管理者権限はあるが、対象リソースの読み取り権限がないユーザーを作成
  limited_user = User.create!(
    name: "Limited User",
    email: "limited@example.com",
    password: "password"
  )
  
  # 管理者権限のみのロールを作成
  limited_role = Role.create!(
    name: "limited_admin",
    description: "Admin access without specific resource permissions"
  )
  limited_role.permissions << permissions(:admin_manage)
  limited_user.roles << limited_role
  
  login_as(limited_user)
  
  get admin_example_path
  assert_redirected_to root_path
  assert_match /権限がありません/, flash[:error]
end
```

#### 書き込み権限テスト

```ruby
test "should require Resource:write permission for update action" do
  # 読み取り専用ユーザーを作成
  read_only_user = User.create!(
    name: "Read Only User",
    email: "readonly@example.com",
    password: "password"
  )
  
  # 読み取り専用ロールを作成
  read_only_role = Role.create!(
    name: "resource_viewer",
    description: "Read-only access to resources"
  )
  read_only_role.permissions << permissions(:admin_manage)
  read_only_role.permissions << permissions(:resource_read)
  read_only_user.roles << read_only_role
  
  login_as(read_only_user)
  
  # 表示は可能
  get admin_example_path
  assert_response :success
  
  # 更新は不可
  patch admin_example_path, params: { example: { name: "Updated" } }
  assert_redirected_to root_path
  assert_match /権限がありません/, flash[:error]
end
```

### 4. 正常系テスト

```ruby
test "user with appropriate permissions can perform action" do
  login_as_user_manager  # 適切な権限を持つユーザー
  
  get admin_example_path
  assert_response :success
  
  patch admin_example_path, params: { example: { name: "Updated" } }
  assert_redirected_to admin_example_path
  assert_equal "更新しました", flash[:notice]
end
```

## Controller実装パターン

### 1. 基本的な権限チェック

```ruby
class Admin::ExampleController < Admin::ApplicationController
  before_action :set_example, only: [:show, :edit, :update, :destroy]
  before_action :authorize_example_management

  private

  def authorize_example_management
    case action_name
    when 'index', 'show'
      authorize_read!('Example')
    when 'new', 'create', 'edit', 'update'
      authorize_write!('Example')
    when 'destroy'
      authorize_delete!('Example')
    end
  end
end
```

### 2. より細かい権限制御

```ruby
def authorize_example_management
  case action_name
  when 'index'
    authorize_read!('Example')
  when 'show'
    # 特定の条件での読み取り権限
    authorize_read!('Example')
    authorize_read!('ExampleDetail') if @example.has_sensitive_data?
  when 'create', 'update'
    authorize_write!('Example')
    authorize_write!('ExampleDetail') if params[:example][:sensitive_field].present?
  when 'destroy'
    authorize_delete!('Example')
    authorize_manage!('Example') if @example.system_critical?
  end
end
```

## Fixtureの設定

### 1. 基本的なロールと権限

```yaml
# test/fixtures/roles.yml
admin:
  name: admin
  description: System administrator
  system_role: true

user_manager:
  name: user_manager
  description: User manager
  system_role: true

example_viewer:
  name: example_viewer
  description: Example viewer only
  system_role: false
```

```yaml
# test/fixtures/permissions.yml
example_read:
  resource_type: Example
  action: read
  description: Example読み取り権限

example_write:
  resource_type: Example
  action: write
  description: Example書き込み権限
```

```yaml
# test/fixtures/role_permissions.yml
admin_example_manage:
  role: admin
  permission: example_manage

user_manager_example_read:
  role: user_manager
  permission: example_read

example_viewer_read:
  role: example_viewer
  permission: example_read
```

### 2. テストユーザーの設定

```yaml
# test/fixtures/users.yml
example_viewer_user:
  name: Example Viewer
  email: viewer@example.com
  password_digest: <%= BCrypt::Password.create('password') %>
  totp_secret: JBSWY3DPEHPK3PXP
  totp_enabled: false
  verified: true
```

```yaml
# test/fixtures/user_roles.yml
example_viewer_role:
  user: example_viewer_user
  role: example_viewer
```

## テストの網羅性チェックリスト

### 必須テスト項目

- [ ] **認証テスト**: 未ログインユーザーのリダイレクト
- [ ] **基本認可テスト**: 権限なしユーザーのアクセス拒否
- [ ] **読み取り権限テスト**: 各表示アクションの権限チェック
- [ ] **書き込み権限テスト**: 各更新アクションの権限チェック
- [ ] **削除権限テスト**: 削除アクションの権限チェック
- [ ] **正常系テスト**: 適切な権限での正常動作

### 追加テスト項目（必要に応じて）

- [ ] **段階的権限テスト**: 部分的権限での制限動作
- [ ] **システムロール保護**: システムロールの変更不可
- [ ] **使用中リソース保護**: 使用中リソースの削除不可
- [ ] **権限継承テスト**: manage権限による他権限の自動取得
- [ ] **複数ロールテスト**: 複数ロール所持時の権限合成

## エラーレスポンスの検証

### 通常のHTTPリクエスト

```ruby
# 権限なしの場合 - root_pathへリダイレクト
assert_redirected_to root_path
assert_match /権限がありません/, flash[:error]
```

### AjaxリクエストやTurbo Stream

```ruby
# AjaxやTurbo Streamの場合 - 403 Forbiddenを返す
get admin_example_path, xhr: true
assert_response :forbidden
```

## ベストプラクティス

### 1. テストの構造化

```ruby
class Admin::ExampleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:admin_user)
    @example = examples(:one)
    # 共通setup
  end

  # グループ1: 認証・認可テスト
  test "authentication and authorization..." do
    # 認証・認可関連のテスト
  end

  # グループ2: 正常系テスト
  test "successful operations..." do
    # 正常系のテスト
  end

  # グループ3: エラー系テスト
  test "error handling..." do
    # エラー処理のテスト
  end
end
```

### 2. DRY原則の適用

```ruby
# 共通のテストヘルパーを作成
def assert_permission_required(action, permission_type)
  # 権限チェックの共通ロジック
end

def create_user_with_permissions(*permissions)
  # 特定権限を持つユーザー作成の共通ロジック
end
```

### 3. テストの保守性

- テスト名は具体的で分かりやすく
- 一つのテストで一つの観点のみを検証
- fixture を活用して重複を避ける
- コメントで複雑な権限ロジックを説明

## トラブルシューティング

### よくある問題

1. **fixture の権限設定ミス**
   - `db/seeds.rb` と fixture の権限設定が一致しているか確認

2. **権限チェックの順序**
   - `before_action` の順序が適切か確認
   - より具体的な権限チェックを後に配置

3. **テストの独立性**
   - 各テストが他のテストに影響を与えていないか確認
   - データベースの状態をテスト間でリセット

### デバッグ方法

```ruby
# 権限の確認
puts current_user.roles.map(&:name)
puts current_user.permissions.map { |p| "#{p.resource_type}:#{p.action}" }

# 権限チェックの詳細確認
def authorize_example_management
  Rails.logger.debug "Action: #{action_name}"
  Rails.logger.debug "User permissions: #{current_user.permissions.pluck(:resource_type, :action)}"
  
  case action_name
  when 'show'
    Rails.logger.debug "Checking Example:read permission"
    authorize_read!('Example')
  end
end
```

このガイドに従って権限テストを実装することで、堅牢で保守可能な権限システムを構築できます。