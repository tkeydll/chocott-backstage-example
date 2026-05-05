# Azureリソースデプロイテンプレート

Backstageテンプレートを使用して、Bicepで定義したAzureリソースをGitHub Actionsで自動デプロイするテンプレートです。

## 特徴

- ✅ **Bicepベース** - Infrastructure as Codeの最新ベストプラクティス
- ✅ **自動デプロイ** - GitHub Actions で main ブランチへのプッシュで自動実行
- ✅ **カスタマイズ可能** - パラメータで入力項目をカスタマイズ
- ✅ **セキュア** - サービスプリンシパル認証を使用
- ✅ **検証可能** - デプロイ前にテンプレートをバリデーション可能

## 使用方法

### 1. Backstageからテンプレートを追加

Backstage UIから以下のURLでテンプレートをインポート：

```
https://github.com/ap-communications/chocott-backstage/tree/main/chocott-contents/scaffolders/azure-deploy/template.yaml
```

### 2. テンプレートから新規プロジェクトを作成

1. Backstage で「Create...」を選択
2. 「Azureリソースデプロイテンプレート」を選択
3. 以下の情報を入力：
   - **プロジェクト名** - 小文字、ハイフン、数字のみ
   - **説明** - プロジェクトの説明
   - **Azureサブスクリプション ID** - デプロイ先サブスクリプション
   - **リソースグループ名** - デプロイ先リソースグループ
   - **リージョン** - Japan East, Japan West など
   - **リポジトリロケーション** - GitHub リポジトリURL

### 3. GitHub Secretsを設定

生成されたリポジトリで以下のシークレットを設定：

```bash
gh secret set AZURE_CLIENT_ID -b "<service-principal-client-id>"
gh secret set AZURE_TENANT_ID -b "<service-principal-tenant-id>"
```

### 4. Bicepテンプレートをカスタマイズ

生成されたリポジトリの `bicep/main.bicep` を編集して、デプロイするAzureリソースを定義します。

### 5. デプロイ実行

`main` ブランチへのプッシュで自動的にGitHub Actions が実行されます：

```bash
git push origin main
```

## ディレクトリ構成

```
generated-repo/
├── .github/
│   └── workflows/
│       └── deploy-azure.yml      # GitHub Actionsワークフロー
├── bicep/
│   ├── main.bicep               # Bicepテンプレート
│   └── main.bicepparam          # パラメータファイル
├── catalog-info.yaml            # Backstage カタログ情報
├── README.md                     # 詳細なセットアップガイド
└── .gitignore
```

## Bicepテンプレートの例

### App Service と Database

```bicep
// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${resourceNamePrefix}-asp'
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
  }
}

// PostgreSQL
resource postgresServer 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: '${resourceNamePrefix}-psql'
  location: location
  properties: {
    administratorLogin: 'dbadmin'
    administratorLoginPassword: 'Password123!'
    version: '11'
    storageMB: 51200
  }
}
```

## GitHub Actions ワークフロー

GitHub Actions は以下の処理を実行：

1. **コードをチェックアウト** - リポジトリの最新コードを取得
2. **Azure にログイン** - サービスプリンシパルで認証
3. **リソースグループを作成** - 指定されたリソースグループが存在しない場合は作成
4. **Bicepテンプレートをデプロイ** - `az deployment group create` でリソースをデプロイ
5. **デプロイ結果を出力** - 作成されたリソース一覧を表示

## トラブルシューティング

### GitHub Actions が失敗する

**確認項目:**
- GitHub Secrets が正しく設定されているか
- サービスプリンシパルに Contributor 権限があるか
- Bicepテンプレートの構文が正しいか

**ログ確認:**
```bash
# GitHub CLI でログを確認
gh run list
gh run view <run-id> --log
```

### Bicep テンプレートのバリデーション

```bash
# 構文チェック
az bicep build --file bicep/main.bicep

# デプロイ前検証
az deployment group validate \
  --resource-group myResourceGroup \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam
```

## 参考資料

- [Microsoft Learn - Bicep チュートリアル](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/learn-bicep)
- [GitHub Actions - Azure へのデプロイ](https://docs.github.com/ja/actions/deployment/deploying-to-your-cloud-provider/deploying-to-azure)
- [Backstage - Software Templates](https://backstage.io/docs/features/software-templates/)
