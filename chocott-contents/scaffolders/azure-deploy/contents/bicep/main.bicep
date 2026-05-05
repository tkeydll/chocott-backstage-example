// ============================================================================
// メインBicepテンプレート
// プロジェクト: ${{ values.projectName }}
// 説明: ${{ values.description }}
// ============================================================================

metadata:
  description: 'Azureリソースのデプロイテンプレート'

// パラメータ定義
param location string = '${{ values.location }}'
param projectName string = '${{ values.projectName }}'
param environment string = 'dev'

// 変数定義
var resourceNamePrefix = '${projectName}-${environment}'

// ============================================================================
// リソース定義の例
// ============================================================================

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${resourceNamePrefix}-asp'
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

// App Service (Web App)
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: '${resourceNamePrefix}-app'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|18-lts'
      minTlsVersion: '1.2'
      http20Enabled: true
      defaultDocuments: [
        'index.html'
      ]
    }
  }
}

// ============================================================================
// 出力
// ============================================================================

output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServiceId string = appService.id
output appServicePlanId string = appServicePlan.id
