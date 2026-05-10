# Azure Quickstartテンプレートデプロイ

Backstageテンプレートを使用して、[tkeydll/azure-quickstart-templates](https://github.com/tkeydll/azure-quickstart-templates) リポジトリのARMテンプレートをGitHub Actionsで自動デプロイするテンプレートです。

## 特徴

- ✅ **ARMテンプレートベース** - Azure Quickstartテンプレートをそのまま利用
- ✅ **自動デプロイ** - GitHub Actionsでmainブランチへのプッシュ時に自動実行
- ✅ **複数テンプレート対応** - 用途に合わせて複数のQuickstartテンプレートから選択可能
- ✅ **セキュア** - フェデレーション認証（OIDC）によるサービスプリンシパル認証
- ✅ **バリデーション付き** - デプロイ前にARMテンプレートを自動検証

## 対応テンプレート

| テンプレート名 | 説明 |
|---|---|
| `101-vm-simple-linux` | シンプルなLinux仮想マシン |
| `101-function-app-create-dynamic` | Azure Functions（消費プラン） |
| `101-cosmosdb-create-arm-template` | Azure Cosmos DB |
| `101-storage-account-create` | ストレージアカウント |
| `101-aks` | Azure Kubernetes Service |

## 必要な設定

### Azure側の設定

以下の手順でAzureサービスプリンシパルを作成し、GitHub Secretsに設定します。

#### 1. サービスプリンシパルの作成

```bash
az ad sp create-for-rbac \
  --name "backstage-quickstart-deploy-sp" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --output json
```

出力例：
```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "backstage-quickstart-deploy-sp",
  "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

#### 2. フェデレーション認証の設定（推奨）

GitHub ActionsでOIDC認証を使用する場合は、フェデレーション資格情報を設定します：

```bash
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<GITHUB_ORG>/<REPO_NAME>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### GitHub Secretsの設定

生成されたリポジトリの **Settings > Secrets and variables > Actions** から以下を設定：

| シークレット名 | 説明 |
|---|---|
| `AZURE_CLIENT_ID` | サービスプリンシパルのクライアント ID（`appId`） |
| `AZURE_TENANT_ID` | AzureテナントID（`tenant`） |
| `AZURE_SUBSCRIPTION_ID` | Azureサブスクリプション ID |
| `AZURE_RESOURCE_GROUP` | デプロイ先のリソースグループ名 |
| `AZURE_LOCATION` | デプロイ先のリージョン（例：`japaneast`） |

## 使用方法

### 1. Backstageからテンプレートを追加

Backstage UIから以下のURLでテンプレートをインポート：

```
https://github.com/tkeydll/chocott-backstage-example/blob/main/chocott-contents/scaffolders/azure-quickstart-deploy/template.yaml
```

### 2. テンプレートから新規プロジェクトを作成

1. Backstageで「Create...」を選択
2. 「Azure Quickstartテンプレートデプロイ」を選択
3. 以下の情報を入力：
   - **プロジェクト名** - 小文字、ハイフン、数字のみ（3〜50文字）
   - **説明** - プロジェクトの説明
   - **デプロイするテンプレート** - Quickstartテンプレートを選択
   - **Azureサブスクリプション ID** - デプロイ先サブスクリプション
   - **リソースグループ名** - デプロイ先リソースグループ
   - **デプロイ先リージョン** - Japan Eastなど
   - **リポジトリロケーション** - GitHubリポジトリURL

### 3. GitHub Secretsを設定

「必要な設定」セクションの手順に従ってGitHub Secretsを設定します。

### 4. ARMテンプレートのパラメータをカスタマイズ

生成されたリポジトリの `arm-template/azuredeploy.parameters.json` を編集して、
テンプレート固有のパラメータを設定します。

### 5. デプロイ実行

`main` ブランチへのプッシュで自動的にGitHub Actionsが実行されます：

```bash
git push origin main
```

## ディレクトリ構成（生成されるリポジトリ）

```
generated-repo/
├── .github/
│   └── workflows/
│       └── deploy-azure.yml      # GitHub Actionsワークフロー
├── arm-template/
│   ├── azuredeploy.json          # ARMテンプレート（Quickstartから取得）
│   └── azuredeploy.parameters.json  # パラメータファイル
├── catalog-info.yaml             # Backstageカタログ情報
├── README.md                     # セットアップガイド
└── .gitignore
```

## トラブルシューティング

### GitHub Actionsが失敗する

**確認項目:**
- GitHub Secretsが正しく設定されているか
- サービスプリンシパルにContributorロールがあるか
- `azuredeploy.parameters.json` のパラメータが正しいか

**ログ確認:**
```bash
gh run list
gh run view <run-id> --log
```

### ARMテンプレートのバリデーション

```bash
az deployment group validate \
  --resource-group <RESOURCE_GROUP> \
  --template-file arm-template/azuredeploy.json \
  --parameters arm-template/azuredeploy.parameters.json
```

## 参考資料

- [tkeydll/azure-quickstart-templates](https://github.com/tkeydll/azure-quickstart-templates)
- [Microsoft Learn - ARMテンプレートドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/templates/overview)
- [GitHub Actions - Azure へのデプロイ](https://docs.github.com/ja/actions/deployment/deploying-to-your-cloud-provider/deploying-to-azure)
- [Backstage - Software Templates](https://backstage.io/docs/features/software-templates/)
