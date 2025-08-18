# ルーティング設計ガイドライン

参照記事:
[How DHH organizes his Rails controllers](https://jeromedalbert.com/how-dhh-organizes-his-rails-controllers/)

## 基本原則

### 1. RESTfulルーティングを優先する

- 標準的な7つのアクション（index, show, new, edit, create, update,
  destroy）を使用
- カスタムアクションではなく、新しいリソースとしてモデリング

```ruby
# ❌ 悪い例：カスタムアクションを追加
resources :inboxes do
  member do
    get :pendings
    post :archive
  end
end

# ✅ 良い例：専用リソースとして定義
resources :inboxes, only: [:index, :show, :new, :create, :edit, :update, :destroy]
namespace :inboxes do
  resources :pendings, only: [:index]
  resources :archives, only: [:create]
end
```

### 2. 名前空間を活用した組織化

- 関連する機能は名前空間でグループ化
- コントローラーの責務を明確に分離

```ruby
# ✅ 良い例：名前空間による整理
namespace :tasks do
  resources :assignments, only: [:create, :destroy]
  resources :completions, only: [:create, :destroy]
  resources :comments, only: [:index, :create, :destroy]
end

namespace :projects do
  resources :memberships, only: [:index, :create, :destroy]
  resources :invitations, only: [:create, :show, :update]
end
```

### 3. 単一責務の原則

- 1つのコントローラーは1つの責務のみを持つ
- 複雑な操作は専用コントローラーに分離

```ruby
# ❌ 悪い例：複数の責務を持つコントローラー
class TasksController < ApplicationController
  def index; end
  def show; end
  def create; end
  def complete; end      # 完了処理
  def assign; end        # 割り当て処理
  def duplicate; end     # 複製処理
end

# ✅ 良い例：責務ごとにコントローラーを分離
class TasksController < ApplicationController
  # 基本的なCRUD操作のみ
end

class Tasks::CompletionsController < ApplicationController
  # 完了/未完了の切り替え
end

class Tasks::AssignmentsController < ApplicationController
  # タスクの割り当て
end

class Tasks::DuplicationsController < ApplicationController
  # タスクの複製
end
```

## 実装例

### 現在のアプリケーションでの適用例

```ruby
# プロジェクト関連
resources :projects, only: [:index, :show, :new, :create, :edit, :update, :destroy]

namespace :projects do
  resources :memberships, only: [:create, :destroy]
  resources :task_assignments, only: [:index]
end

# タスク関連
resources :tasks, only: [:index, :show, :new, :create, :edit, :update, :destroy]

namespace :tasks do
  resources :completions, only: [:create, :destroy]
  resources :suggestions, only: [:index, :create]
  resources :comments, only: [:create, :destroy]
end

# 認証関連
resource :session, only: [:new, :create, :destroy]
resources :password_resets, only: [:new, :create, :edit, :update]
resources :email_verifications, only: [:show, :create]
```

## 判断基準

### 新しいコントローラーを作成すべき場合

- 既存のRESTアクションでは表現できない操作
- 複数のモデルを横断する複雑な処理
- 特定の状態変更に特化した操作

### 例：タスクの一括操作

```ruby
# ❌ 悪い例
class TasksController < ApplicationController
  def bulk_complete; end
  def bulk_assign; end
  def bulk_delete; end
end

# ✅ 良い例
namespace :tasks do
  resources :bulk_operations, only: [:create] do
    collection do
      post :complete
      post :assign
      post :delete
    end
  end
end
```

## まとめ

- RESTful設計を最優先とする
- カスタムアクションではなく新しいリソースとして考える
- 名前空間を使って関連機能をグループ化する
- 各コントローラーの責務を明確に定義する
- 複雑さが増した場合は積極的にコントローラーを分割する
