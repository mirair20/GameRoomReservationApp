resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'gameroomstorageaccount'
  location: 'germanywestcentral'
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
  }
}
