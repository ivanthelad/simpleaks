source ../env.sh 
uuid=$(openssl rand -hex 32 | tr -dc 'a-zA-Z0-9' | fold -w 5  | head -n 1)
clusternameparam=$1
function  isempty ()
{
   paramname="$1"
   paramvalue="$2"

      if test -z "$paramvalue" 
      then
            echo -e "   \e[31mError\e[0m:$paramname is EMPTY, Please paas a parameter for the $paramname"
          return 0 
     else
           echo  -e "   \e[32m OK\e[0m   :$paramname=$paramvalue is set"
      fi
      return 1

}
function  sanitycheck ()
{

      errors=0;
      if  isempty "clusternameparam" "$clusternameparam"; then 
            echo -e "      \e[31mError\e[0m: No param passed to script. A cluster name is required to be passed to script"
            errors=$((errors+1))
      fi
      if  isempty "SP_ID" "$SP_ID"; then 
            errors=$((errors+1))
      fi
      if  isempty "SP_PASS" "$SP_PASS"; then 
            errors=$((errors+1))
      fi
      if  isempty "SUBSCRIPTIONID" "$SUBSCRIPTIONID"; then 
            errors=$((errors+1))
      fi  
      if [ $errors -gt 0 ]; then
          echo -e "   \e[31mEncountered $errors in parameters. Please fix before continuing. exiting \e[0m "
          exit 1;
      fi 
}
##sanitycheck
 

KEYVAULT="$clusternameparam"
RESOURCE_GROUP=$KEYVAULT
AKS_CLUSTER=$KEYVAULT
AKS_KEYVAULT_KEYNAME="akskey"
AKS_ENCRYPTION_SET="aksencryptionset"
KUBE_VERSION=1.17.9
LOCATION=westeurope
echo "Creating keyvault with name $KEYVAULT in RG $RESOURCE_GROUP "

## create the share resource group 
echo "0 create group"
az group create -l $LOCATION -n $RESOURCE_GROUP

echo "1: create keyvault"
## Create keyvault group
az keyvault create -n $KEYVAULT -g $RESOURCE_GROUP -l $LOCATION  --enable-purge-protection true --enable-soft-delete true

echo "2: create key in keyvault"
## Create a key to use 
az keyvault key create --vault-name $KEYVAULT  --name $AKS_KEYVAULT_KEYNAME --protection software

echo "3: getting keyvaultid"
## get keyvault id 
keyVaultId=$(az keyvault show --name $KEYVAULT --query [id] -o tsv)

echo "4: keyvault url"
## Get keyvault url that references a key.
keyVaultKeyUrl=$(az keyvault key show --vault-name $KEYVAULT  --name $AKS_KEYVAULT_KEYNAME  --query [key.kid] -o tsv)

echo "5: getting encryption set"
## create encryption set 
az disk-encryption-set create -n $AKS_ENCRYPTION_SET  -l $LOCATION  -g $RESOURCE_GROUP --source-vault $keyVaultId --key-url $keyVaultKeyUrl 

# Retrieve the DiskEncryptionSet value and set a variable
echo "6: getting disk encryption identity"
desIdentity=$(az disk-encryption-set show -n $AKS_ENCRYPTION_SET  -g $RESOURCE_GROUP --query [identity.principalId] -o tsv)

echo "7: update security policy"
# Update security policy settings
az keyvault set-policy -n $KEYVAULT  -g $RESOURCE_GROUP --object-id $desIdentity --key-permissions wrapkey unwrapkey get

echo "8: getting DISK_ENCRYPTION_SET_ID"
## getting DISK_ENCRYPTION_SET_ID
DISK_ENCRYPTION_SET_ID=$(az resource show -n $AKS_ENCRYPTION_SET -g $RESOURCE_GROUP --resource-type "Microsoft.Compute/diskEncryptionSets" --query [id] -o tsv)

echo "Got DISK_ENCRYPTION_SET_ID $DISK_ENCRYPTION_SET_ID "
echo -e "      \e[33m DISK_ENCRYPTION_SET_ID found, please copy past this ID and use it in 'az aks create --node-osdisk-diskencryptionset-id=$DISK_ENCRYPTION_SET_ID '\e[0m: "


####################
##
## Creating A CMK based ACR
## https://docs.microsoft.com/en-us/azure/container-registry/container-registry-customer-managed-keys#enable-customer-managed-key---cli
##
####################


echo "9: Creating ACR identity in RG $RESOURCE_GROUP "
## Lets create an identity. this is required to pull the key for the registry 
az identity create --name $clusternameparam-acr-ident --resource-group $RESOURCE_GROUP
echo "10:  Finding ACR identity "
## Finding ACR  identity
ACR_IDENTITY_ID=$(az identity show --name  $clusternameparam-acr-ident --resource-group $RESOURCE_GROUP --query 'id' --output tsv)
echo "11: Finding ACR principal id "

## Finding ACR  identity
ACR_IDENTITY_ID_PRINCIPALID=$(az identity show --name $clusternameparam-acr-ident --resource-group $RESOURCE_GROUP --query 'principalId' --output tsv)
echo "12: setting keyvault access "

##az keyvault key show  --name <keyname>  --vault-name <key-vault-name>  --query 'key.kid' --output tsv

## Add key vault access policy
az keyvault set-policy \
  --resource-group $RESOURCE_GROUP  \
  --name $KEYVAULT  \
  --object-id $ACR_IDENTITY_ID_PRINCIPALID \
  --key-permissions get unwrapKey wrapKey 
echo "13: creating ACR "
## create the ACR with key 
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name ${clusternameparam}ACR \
  --identity $ACR_IDENTITY_ID \
  --key-encryption-key $keyVaultKeyUrl \
  --sku Premium
echo "13: creating ACR ID "
ACR_REGISTRY_ID=$(az acr show -n  ${clusternameparam}ACR -g $RESOURCE_GROUP --query 'id' -o tsv)
echo "14: Got DISK_ENCRYPTION_SET_ID $DISK_ENCRYPTION_SET_ID "
echo -e "      \e[33m DISK_ENCRYPTION_SET_ID found, please copy past this ID and use it in 'az aks create --node-osdisk-diskencryptionset-id=$DISK_ENCRYPTION_SET_ID '\e[0m: "


echo "   \e[31m ############################## \e[0m: "
echo "   \e[31m Please note the following variables. they are required for creating a CMK enable AKS cluster attached to CMK enable ACR \e[0m: "
echo  -e "      \e[32m - \e[0m   "
echo  -e "      \e[32m - \e[0m   "
echo  -e "      \e[32m ACR_REGISTRY_ID\e[0m   :$ACR_REGISTRY_ID "
echo  -e "     \e[32m DISK_ENCRYPTION_SET_ID \e[0m   :$DISK_ENCRYPTION_SET_ID"
echo  -e "      \e[32m - \e[0m   "
echo  -e "      \e[32m - \e[0m   "

