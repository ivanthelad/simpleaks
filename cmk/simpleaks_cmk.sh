#!/bin/bash
## enable app insights https://github.com/microsoft/Application-Insights-K8s-Codeless-Attach
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
      if  isempty "DISK_ENCRYPTION_SET_ID" "$DISK_ENCRYPTION_SET_ID"; then
            echo -e "      \e[31m DISK_ENCRYPTION_SET_ID is not set. aborting \e[0m "
             errors=$((errors+1))
      fi
      if  isempty "AAD_ADMIN_GROUP_ID" "$AAD_ADMIN_GROUP_ID"; then
            echo -e "      \e[31m AAD_ADMIN_GROUP_ID is not set. aborting \e[0m "
             errors=$((errors+1))
      fi
      if  isempty "WORKSPACE_ID" "$WORKSPACE_ID"; then
            echo -e "      \e[33mWarn\e[0m: WORKSPACE_ID not set. A new log analytics workspace will be created and used"
      fi
      if  isempty "ACR_REGISTRY" "$ACR_REGISTRY"; then
             echo -e "     \e[33mWarn\e[0m: ACR_REGISTRY not set. A new Azure Container Registry  will be created and used"
      fi
      if  isempty "SUBNET_ID" "$SUBNET_ID"; then
            echo -e "      \e[33mWarn\e[0m: SUBNET_ID not set. A new Azure Container Registry  will be created and used"
      fi

      if [ $errors -gt 0 ]; then
          echo -e "   \e[31mEncountered $errors in parameters. Please fix before continuing. exiting \e[0m "
          exit 1;
      fi
}
sanitycheck


aksname="$clusternameparam"
registryname="${clusternameparam}reg"
echo "Creating cluster with name $aksname "

RESOURCE_GROUP=$aksname
AKS_CLUSTER=$aksname
INGRESS_SUBNET_ID=""

network_prefix='10.3.0.0/16'
network_aks_subnet='10.3.0.0/22'
network_aks_system='10.3.4.0/24'
network_aks_ingress='10.3.5.0/24'

LB_IDLE_TIMEOUT=10
OS_DISK_SIZE=50
## Some basic tags
tags=`echo Environment=dev Project=minipoc Department=engineering`
pool_tags=`echo Environment=dev Project=minipoc Department=engineering`

## az acr show --name aksonazure      --resource-group aksonazure      --query "id" --output tsv

# Create a RG and grab its resource id
RESOURCE_GROUP_ID=$(az group create --name $RESOURCE_GROUP -l $LOCATION --subscription $SUBSCRIPTIONID --tags $tags --query id -o tsv)

if test -z "$WORKSPACE_ID"
then
      echo "WORKSPACE_ID is empty, Gona create a Log analytics workspace in RG $RESOURCE_GROUP "
      az monitor log-analytics workspace create --workspace-name $aksname-logs -g $RESOURCE_GROUP -l $LOCATION --subscription $SUBSCRIPTIONID --tags $tags
      WORKSPACE_ID="$(az monitor log-analytics workspace show --workspace-name $aksname-logs -g $RESOURCE_GROUP --query id  -o tsv --subscription $SUBSCRIPTIONID)"
      echo "created log analytics workspace with id $WORKSPACE_ID"
else
      echo "\Workspace_id is is NOT empty. using $WORKSPACE_ID "
fi
#Create a VNET
if test -z "$SUBNET_ID"
then
      echo "SUBNET_ID is empty, Gona create a custom vnet in RG $RESOURCE_GROUP "
      az network vnet create -g $RESOURCE_GROUP -n $aksname --address-prefix $network_prefix  --tags $tags --subnet-name aks --subnet-prefix $network_aks_subnet -l $LOCATION  --subscription $SUBSCRIPTIONID
      SUBNET_ID="$(az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $aksname --query [].id --output tsv  --subscription $SUBSCRIPTIONID   | grep aks)"
      az network vnet subnet create -n ingress --vnet-name $aksname --address-prefix $network_aks_ingress  -g $RESOURCE_GROUP
      INGRESS_SUBNET_ID="$(az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $aksname --query [].id --output tsv  --subscription $SUBSCRIPTIONID   | grep aks)"


else
      echo "\SUBNET_ID is is NOT empty. using $SUBNET_ID "
fi
## Create an identity if AKS_IDENTITY_ID is not set
if test -z "$AKS_IDENTITY_ID"
then
      echo "AKS_IDENTITY is empty, Gona create a identity in RG $RESOURCE_GROUP "
      ## Lets create an identity

      az identity create --name $aksname-aks-controlplane --resource-group $RESOURCE_GROUP
      ## Finding an identity
      ## old way AKS_IDENTITY_ID=$(az identity list --query "[?name=='shinny-8ea6b-agentpool'].{Id:id}" -o tsv)
      AKS_IDENTITY_ID=$(az identity show --name $aksname-aks-controlplane --resource-group $RESOURCE_GROUP --query 'id' --output tsv)
      AKS_IDENTITY_ID_PRINCIPALID=$(az identity show --name $aksname-aks-controlplane --resource-group $RESOURCE_GROUP --query 'principalId' --output tsv)

else
      echo "\AKS_IDENTITY_ID is is NOT empty. using $AKS_IDENTITY_ID "
fi

if test -z "$ACR_REGISTRY"
then
      echo "ACR_REGISTRY is empty, Gona create a Registry  in RG $RESOURCE_GROUP. This expects an AKS_IDENTITY_ID to be set "
      az acr create -n  $registryname -g $RESOURCE_GROUP -l $LOCATION  --sku standard
      ACR_REGISTRY="$(az acr show -n  $registryname -g $RESOURCE_GROUP --query id  -o tsv --subscription $SUBSCRIPTIONID)"
      echo "created log analytics workspace with id $ACR_REGISTRY"
else
      echo "\ACR_REGISTRY is is NOT empty. using $ACR_REGISTRY "
fi

# Grant read on Disk Encryption Set
# See https://docs.microsoft.com/en-us/azure/aks/azure-disk-customer-managed-keys#encrypt-your-aks-cluster-data-diskoptional
DISK_ENCRYPTION_SET_RESOURCE_GROUP=$(az resource show --id $DISK_ENCRYPTION_SET_ID --query resourceGroup -o tsv)
DISK_ENCRYPTION_SET_RESOURCE_GROUP_ID=$(az group show -g $DISK_ENCRYPTION_SET_RESOURCE_GROUP --query id -o tsv)
az role assignment create \
    --assignee-object-id $AKS_IDENTITY_ID_PRINCIPALID \
    --scope $DISK_ENCRYPTION_SET_RESOURCE_GROUP_ID \
    --role "Contributor"
# Grant Network Contributor and Storage Account Contributor
# See https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal
az role assignment create \
    --assignee-object-id $AKS_IDENTITY_ID_PRINCIPALID  \
    --scope $RESOURCE_GROUP_ID \
    --role "Network Contributor"
az role assignment create \
    --assignee-object-id $AKS_IDENTITY_ID_PRINCIPALID  \
    --scope $RESOURCE_GROUP_ID \
    --role "Storage Account Contributor"

#List Subnet belonging to VNET
echo $SUBNET_ID
## --service-principal $SP_ID \
## --client-secret $SP_PASS \

#Create AKS Cluster with Service Principle
az aks create \
 --enable-managed-identity \
 --assign-identity $AKS_IDENTITY_ID \
 --resource-group $RESOURCE_GROUP \
 --network-plugin $NETWORK_PLUGIN \
 --node-count $MIN_NODE_COUNT \
 --node-vm-size=$VM_SIZE \
 --kubernetes-version=$KUBE_VERSION \
 --name $AKS_CLUSTER \
 --docker-bridge-address "172.17.0.1/16" \
 --dns-service-ip "10.19.0.10" \
 --service-cidr "10.19.0.0/16" \
 --location $LOCATION \
 --enable-addons monitoring \
 --vm-set-type "VirtualMachineScaleSets"   \
 --tags $tags \
 --nodepool-name="basepool" \
 --vnet-subnet-id $SUBNET_ID \
 --enable-cluster-autoscaler \
 --min-count $MIN_NODE_COUNT \
 --max-count $MAX_NODE_COUNT \
 --subscription $SUBSCRIPTIONID \
 --workspace-resource-id $WORKSPACE_ID \
 --nodepool-tags $pool_tags \
 --nodepool-labels $pool_tags \
 --generate-ssh-keys \
 --node-resource-group $RESOURCE_GROUP-managed \
 --enable-managed-identity \
 --skip-subnet-role-assignment \
 --node-osdisk-diskencryptionset-id $DISK_ENCRYPTION_SET_ID \
 --zones 3 \
 --attach-acr $ACR_REGISTRY \
 --enable-aad \
 --aad-admin-group-object-ids $AAD_ADMIN_GROUP_ID

echo "AKS Deployed "
 exit 0;
##  --enable-aad \
## --aad-admin-group-object-ids "f7976ea3-24ae-40a2-b546-00c369910444" \
echo "adding system pool "
az aks nodepool add -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n systemnodes --node-taints CriticalAddonsOnly=true:NoSchedule --mode system
echo "traefik ingress pool"
if  isempty "INGRESS_SUBNET_ID" "$INGRESS_SUBNET_ID"; then
     echo -e "      \e[31mError\e[0m: no ingress subnet id found. will not create pool"
     errors=$((errors+1))
else
      az aks nodepool add -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n ingress --vnet-subnet-id $INGRESS_SUBNET_ID --node-taints IngressOnly=true:NoSchedule --node-count=2 --node-count=2 --tags="Ingress=true"

fi

# security policy
