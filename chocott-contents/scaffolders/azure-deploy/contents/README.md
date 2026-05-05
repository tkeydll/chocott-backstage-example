# ${{ values.projectName }}

${{ values.description }}

## 概要

このリポジトリは、Backstageから自動生成されたAzureインフラストラクチャコードです。  
GitHub Actionsを使用してAzureリソースを自動デプロイします。

## セットアップ手順

### 1. GitHub Secretsの設定

リポジトリの以下のシークレットを設定してください：

| シークレット名 | 説明 |
|---|---|
| `AZURE_CLIENT_ID` | Azureサービスプリンシパルのクライアント ID |
| `AZURE_TENANT_ID` | Azureテナント ID |
| `AZURE_SUBSCRIPTION_ID` | Azureサブスクリプション ID（`${{ values.azureSubscriptionId }}`） |
| `AZURE_RESOURCE_GROUP` | デプロイ先のリソースグループ名（`${{ values.resourceGroupName }}`） |
| `AZURE_LOCATION` | デプロイ先のリージョン（`${{ values.location }}`） |

#### 設定コマンド例

```bash
gh secret set AZURE_SUBSCRIPTION_ID -b "${{ values.azureSubscriptionId }}"
gh secret set AZURE_RESOURCE_GROUP -b "${{ values.resourceGroupName }}"
gh secret set AZURE_LOCATION -b "${{ values.location }}"
```

### 2. サービスプリンシパルの作成

Azure CLIを使用してサービスプリンシパルを作成：

```bash
az ad sp create-for-rbac \
  --name "backstage-deploy-sp" \
  --role Contributor \
  --scopes /subscriptions/${{ values.azureSubscriptionId }} \
  --output json
```

出力された値を以下のシークレットに設定：
- `appId` → `AZURE_CLIENT_ID`
- `tenant` → `AZURE_TENANT_ID`

### 3. Bicepテンプレートのカスタマイズ

`bicep/main.bicep`を編集して、デプロイするAzureリソースを定義します：

```bicep
// リソースの例
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${resourceNamePrefix}sa'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
```

## デプロイ

### 自動デプロイ

`main`ブランチへのプッシュで自動的にGitHub Actionsが実行されます：

```bash
git add bicep/
git commit -m "Update Bicep template"
git push origin main
```

### 手動デプロイ

GitHub UIで`Actions`タブから`Deploy Azure Resources`ワークフローを実行：

1. GitHub リポジトリの`Actions`タブを開く
2. `Deploy Azure Resources`を選択
3. `Run workflow`をクリック

## Bicepテンプレートのバリデーション

デプロイ前にBicepテンプレートをローカルで検証：

```bash
az bicep build --file bicep/main.bicep
az deployment group validate \
  --resource-group "${{ values.resourceGroupName }}" \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam
```

## リソースの確認

デプロイ後、作成されたリソースを確認：

```bash
az resource list \
  --resource-group "${{ values.resourceGroupName }}" \
  --output table
```

## トラブルシューティング

### デプロイが失敗する場合

GitHub Actionsのログを確認：

1. `Actions`タブで失敗したワークフローを選択
2. ジョブのログを確認
3. エラーメッセージに基づいて対応

一般的な問題：
- **認証エラー**: Secretsが正しく設定されているか確認
- **権限エラー**: サービスプリンシパルにContributor権限があるか確認
- **リソース作成失敗**: Bicepテンプレートの構文を確認

## さらに学ぶ

- [Bicep ドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/overview)
- [Backstage テンプレート](https://backstage.io/docs/features/software-templates/)
- [GitHub Actions ドキュメント](https://docs.github.com/ja/actions)
