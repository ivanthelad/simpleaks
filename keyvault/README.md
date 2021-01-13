RESOURCE_GROUP="teamResources-3"

KEYVAULT_NAME="vault-aks-secret-test5"
## Create the Azure Key Vault
# https://docs.microsoft.com/en-us/azure/key-vault/secrets/quick-create-cli
az keyvault create --name $KEYVAULT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION
## Create the Azure Keyvault Secret
az keyvault secret set --vault-name $KEYVAULT_NAME --name $SecretName --value $SecretValue
## Configure AKV policy to the Service Principal
az role assignment create --role Reader --assignee $spID --scope /subscriptions/$subID/resourcegroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME
az keyvault set-policy -n $KEYVAULT_NAME --secret-permissions get --spn $spID
