#!/bin/bash
## neable app insights https://github.com/microsoft/Application-Insights-K8s-Codeless-Attach
source ./env.sh 
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


      if  isempty "SUBSCRIPTIONID" "$SUBSCRIPTIONID"; then 
            errors=$((errors+1))
      fi  
      if  isempty "AAD_ADMIN_GROUP_ID" "$AAD_ADMIN_GROUP_ID"; then 
            echo -e "      \e[33mWarn\e[0m: AAD_ADMIN_GROUP_ID not set. Fix me "
            errors=$((errors+1))
      fi
      if  isempty "AAD_TENANT_ID" "$AAD_TENANT_ID"; then
             echo -e "      \e[33mWarn\e[0m: AAD_TENANT_ID not set. Fix me "

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
      if  isempty "AKS_IDENTITY_ID" "$AKS_IDENTITY_ID"; then 
            echo -e "      \e[33mWarn\e[0m: AKS_IDENTITY_ID not set. A new user managed identity  will be created and used"
      fi
      if [ $errors -gt 0 ]; then
          echo -e "   \e[31mEncountered $errors in parameters. Please fix before continuing. exiting \e[0m "
          exit 1;
      fi 
}
sanitycheck
 

aksname="$clusternameparam-$uuid"
registryname="${clusternameparam}${uuid}reg"
echo "Creating cluster with name $aksname "

RESOURCE_GROUP=$aksname
AKS_CLUSTER=$aksname
AKS_IDENTITY_NAME=$aksname
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
echo $LOCATION
#Create a RG
az group create --name  $RESOURCE_GROUP -l $LOCATION  --subscription $SUBSCRIPTIONID --tags $tags
az identity create -g  $RESOURCE_GROUP -n $RESOURCE_GROUP
if test -z "$AKS_IDENTITY_ID" 
then
      echo "AKS_IDENTITY_ID is empty, Gona create a Registry  in RG $RESOURCE_GROUP "
      az identity create -n  $AKS_IDENTITY_NAME -g $RESOURCE_GROUP 
      AKS_IDENTITY_ID="$(az identity show -n  $AKS_IDENTITY_NAME -g $RESOURCE_GROUP --query id -o tsv --subscription $SUBSCRIPTIONID)"
      echo "created USER managed identity with id $AKS_IDENTITY_ID" 
else
      echo "\AKS_IDENTITY_ID is is NOT empty. using $AKS_IDENTITY_ID "
fi

if test -z "$ACR_REGISTRY" 
then
      echo "ACR_REGISTRY is empty, Gona create a Registry  in RG $RESOURCE_GROUP "
      az acr create -n  $registryname -g $RESOURCE_GROUP -l $LOCATION  --sku standard
      ACR_REGISTRY="$(az acr show -n  $registryname -g $RESOURCE_GROUP --query id  -o tsv --subscription $SUBSCRIPTIONID)"
      echo "created log analytics workspace with id $ACR_REGISTRY" 
else
      echo "\ACR_REGISTRY is is NOT empty. using $ACR_REGISTRY "
fi

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

#Create a AKS subnet. not needed. created above. 
#az network vnet subnet create -g $RESOURCE_GROUP --vnet-name iotsuite -n $AKS_CLUSTER  --address-prefix 10.0.1.0/24  --subscription $SUBSCRIPTIONID


#List Subnet belonging to VNET
echo $SUBNET_ID
## --service-principal $SP_ID \
## --client-secret $SP_PASS \
echo managed identity $AKS_IDENTITY_ID
USER_ASSIGNED_IDENTITY_CLIENTID="$(  az identity show  --ids $AKS_IDENTITY_ID --query clientId -o tsv)"
AKS_VNET_RG=$(echo $SUBNET_ID|cut -d'/' -f 5) 
AKS_VNET=$(echo $SUBNET_ID| cut -d'/' -f 9)
echo $AKS_VNET_RG ..... $AKS_VNET .... $USER_ASSIGNED_IDENTITY_CLIENTID

az role assignment create --assignee $USER_ASSIGNED_IDENTITY_CLIENTID --role "Contributor" --scope /subscriptions/$SUBSCRIPTIONID/resourceGroups/$AKS_VNET_RG/providers/Microsoft.Network/virtualNetworks/$AKS_VNET
az role assignment create --assignee $USER_ASSIGNED_IDENTITY_CLIENTID --role "Network Contributor" --scope /subscriptions/$SUBSCRIPTIONID/resourceGroups/$AKS_VNET_RG/providers/Microsoft.Network/virtualNetworks/$AKS_VNET

#Create AKS Cluster with Service Principle
az aks create \
 --resource-group $RESOURCE_GROUP \
 --network-plugin $NETWORK_PLUGIN \
 --node-count $MIN_NODE_COUNT \
 --node-vm-size=$VM_SIZE \
 --kubernetes-version=$KUBE_VERSION \
 --name $AKS_CLUSTER \
 --docker-bridge-address "172.17.0.1/16" \
 --dns-service-ip "10.19.0.10" \
 --service-cidr "10.19.0.0/16" \
 --pod-cidr "10.244.0.0/16" \
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
 --zones 3 \
 --node-resource-group $RESOURCE_GROUP-managed \
 --attach-acr $ACR_REGISTRY \
 --enable-managed-identity \
 --enable-aad --aad-admin-group-object-ids $AAD_ADMIN_GROUP_ID --aad-tenant-id $AAD_TENANT_ID \
 --assign-identity $AKS_IDENTITY_ID


#  --node-resource-group $RESOURCE_GROUP-managed \
# --aks-custom-headers usegen2vm=true --enable-pod-identity  \
 az aks get-credentials -n $AKS_CLUSTER -g $RESOURCE_GROUP 



## get the managed identity 
#USER_ASSIGNED_IDENTITY_CLIENTID="$(  az identity show  --name $AKS_IDENTITY_NAME  -g $RESOURCE_GROUP  --query clientId -o tsv)"
#AKS_VNET_RG=$(echo $SUBNET_ID|cut -d'/' -f 5) 
#AKS_VNET=$(echo $SUBNET_ID| cut -d'/' -f 9)

#az role assignment create --assignee $USER_ASSIGNED_IDENTITY_CLIENTID --role "Contributor" --scope /subscriptions/$SUBSCRIPTIONID/resourceGroups/$AKS_VNET_RG/providers/Microsoft.Network/virtualNetworks/$AKS_VNET
#az role assignment create --assignee $USER_ASSIGNED_IDENTITY_CLIENTID --role "Network Contributor" --scope /subscriptions/$SUBSCRIPTIONID/resourceGroups/$AKS_VNET_RG/providers/Microsoft.Network/virtualNetworks/$AKS_VNET

echo "adding system pool "
az aks nodepool add -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n systemnodes --node-taints CriticalAddonsOnly=true:NoSchedule --mode system --node-count=1
echo "traefik ingress pool"
if  isempty "INGRESS_SUBNET_ID" "$INGRESS_SUBNET_ID"; then 
     echo -e "      \e[31mError\e[0m: no ingress subnet id found. will not create pool"
     errors=$((errors+1))
else 
      az aks nodepool add --mode user -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n ingress --vnet-subnet-id $INGRESS_SUBNET_ID --node-taints IngressOnly=true:NoSchedule --node-count=1  --tags="Ingress=true"
fi
## remove normal pool. Cos you cannot update the min to zero 

az aks nodepool delete -g  $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n basepool 
## 
az aks nodepool add --zones 3 --mode user -g $RESOURCE_GROUP --cluster-name $AKS_CLUSTER -n apppool --tags="Apps=true" --min-count $MIN_NODE_COUNT --max-count $MAX_NODE_COUNT  --enable-cluster-autoscaler

# security policy  

# --enable-pod-security-policy  \
az aks get-credentials -n $AKS_CLUSTER -g $RESOURCE_GROUP

exit 0;
##https://strimzi.io/docs/latest/full.html#deploying-cluster-operator-helm-chart-str
kubectl  create namespace kafka
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
## see https://strimzi.io/docs/operators/master/using.html#deploying-cluster-operator-helm-chart-str
helm repo add strimzi https://strimzi.io/charts/

helm install strimy strimzi/strimzi-kafka-operator -n kafka --set watchAnyNamespace=true -n kafka 

kubectl create clusterrolebinding strimzi-cluster-operator-namespaced --clusterrole=strimzi-cluster-operator-namespaced --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-entity-operator-delegation --clusterrole=strimzi-entity-operator --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-topic-operator-delegation --clusterrole=strimzi-topic-operator --serviceaccount kafka:strimzi-cluster-operator
kubectl set env deployment strimzi-cluster-operator STRIMZI_NAMESPACE="*" 
kafkaversion="0.18.0"
kubectl apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/$kafkaversion/examples/kafka/kafka-persistent.yaml
