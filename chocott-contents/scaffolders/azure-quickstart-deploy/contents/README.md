# ${{ values.projectName }}

${{ values.description }}

## 概要

このリポジトリは、BackstageからAzure Quickstartテンプレート **`${{ values.templateName }}`** を使って自動生成されたAzureインフラストラクチャコードです。
GitHub Actionsを使用してAzureリソースを自動デプロイします。

**参照テンプレート:** [tkeydll/azure-quickstart-templates/${{ values.templateName }}](https://github.com/tkeydll/azure-quickstart-templates/tree/master/${{ values.templateName }})

## セットアップ手順

### 1. GitHub Secretsの設定

リポジトリの **Settings > Secrets and variables > Actions** から以下のシークレットを設定してください：

| シークレット名 | 説明 | 設定値の例 |
|---|---|---|
| `AZURE_CLIENT_ID` | Azureサービスプリンシパルのクライアント ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | AzureテナントID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID` | Azureサブスクリプション ID | `${{ values.azureSubscriptionId }}` |
| `AZURE_RESOURCE_GROUP` | デプロイ先のリソースグループ名 | `${{ values.resourceGroupName }}` |
| `AZURE_LOCATION` | デプロイ先のリージョン | `${{ values.location }}` |

#### GitHub CLIを使った設定コマンド例

```bash
gh secret set AZURE_SUBSCRIPTION_ID -b "${{ values.azureSubscriptionId }}"
gh secret set AZURE_RESOURCE_GROUP -b "${{ values.resourceGroupName }}"
gh secret set AZURE_LOCATION -b "${{ values.location }}"
gh secret set AZURE_CLIENT_ID -b "<service-principal-client-id>"
gh secret set AZURE_TENANT_ID -b "<service-principal-tenant-id>"
```

### 2. サービスプリンシパルの作成

Azure CLIを使用してサービスプリンシパルを作成し、Contributorロールを付与します：

```bash
az ad sp create-for-rbac \
  --name "backstage-deploy-sp" \
  --role Contributor \
  --scopes /subscriptions/${{ values.azureSubscriptionId }}/resourceGroups/${{ values.resourceGroupName }} \
  --output json
```

出力された値を以下のシークレットに設定します：
- `appId` → `AZURE_CLIENT_ID`
- `tenant` → `AZURE_TENANT_ID`

### 3. ARMテンプレートのパラメータをカスタマイズ

`arm-template/azuredeploy.parameters.json` を編集して、デプロイするリソースのパラメータを設定してください。

各テンプレートのパラメータの詳細は [tkeydll/azure-quickstart-templates/${{ values.templateName }}](https://github.com/tkeydll/azure-quickstart-templates/tree/master/${{ values.templateName }}) を参照してください。

## デプロイ

### 自動デプロイ

`main` ブランチへのプッシュで自動的にGitHub Actionsが実行されます：

```bash
git add arm-template/
git commit -m "Update ARM template parameters"
git push origin main
```

### 手動デプロイ

GitHub UIで **Actions** タブから **Deploy Azure Resources (ARM Template)** ワークフローを実行できます：

1. GitHubリポジトリの **Actions** タブを開く
2. **Deploy Azure Resources (ARM Template)** を選択
3. **Run workflow** をクリック

## ディレクトリ構成

```
.
├── .github/
│   └── workflows/
│       └── deploy-azure.yml      # GitHub Actionsワークフロー
├── arm-template/
│   ├── azuredeploy.json          # ARMテンプレート
│   └── azuredeploy.parameters.json  # パラメータファイル
├── catalog-info.yaml             # Backstageカタログ情報
└── README.md                     # このファイル
```

## トラブルシューティング

### デプロイが失敗する場合

GitHub Actionsのログを確認：

1. **Actions** タブで失敗したワークフローを選択
2. ジョブのログを確認
3. エラーメッセージに基づいて対応

よくある問題：
- **認証エラー**: Secretsが正しく設定されているか確認してください
- **権限エラー**: サービスプリンシパルにContributorロールが付与されているか確認してください
- **パラメータエラー**: `azuredeploy.parameters.json` の値が正しいか確認してください

### ARMテンプレートのローカル検証

```bash
az deployment group validate \
  --resource-group "${{ values.resourceGroupName }}" \
  --template-file arm-template/azuredeploy.json \
  --parameters arm-template/azuredeploy.parameters.json
```

## 参考資料

- [ARMテンプレートドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/templates/overview)
- [GitHub Actions - Azure へのデプロイ](https://docs.github.com/ja/actions/deployment/deploying-to-your-cloud-provider/deploying-to-azure)
- [Backstage - Software Templates](https://backstage.io/docs/features/software-templates/)
- [元テンプレートリポジトリ](https://github.com/tkeydll/azure-quickstart-templates)
