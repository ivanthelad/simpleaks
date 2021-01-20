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
      if  isempty "SP_ID" "$SP_ID"; then 
            errors=$((errors+1))
      fi
      if  isempty "SP_PASS" "$SP_PASS"; then 
            errors=$((errors+1))
      fi
      if  isempty "SUBSCRIPTIONID" "$SUBSCRIPTIONID"; then 
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
 

aksname="$clusternameparam-$uuid"
registryname="${clusternameparam}${uuid}reg"
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

#Create a RG
az group create --name  $RESOURCE_GROUP -l $LOCATION  --subscription $SUBSCRIPTIONID --tags $tags
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

#Create AKS Cluster with Service Principle
az aks create \
 --service-principal $SP_ID \
 --client-secret $SP_PASS \
 --resource-group $RESOURCE_GROUP \
 --network-plugin $NETWORK_PLUGIN \
 --node-count $MIN_NODE_COUNT \
 --node-vm-size=$VM_SIZE \
 --kubernetes-version=$KUBE_VERSION \
 --name $AKS_CLUSTER \
 --docker-bridge-address "19.5.0.1/16" \
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
 --zones 3 --attach-acr $ACR_REGISTRY 
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

# --enable-pod-security-policy  \
az aks get-credentials -n $AKS_CLUSTER -g $RESOURCE_GROUP

exit 0;
##https://strimzi.io/docs/latest/full.html#deploying-cluster-operator-helm-chart-str
kubectl  create namespace kafka
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
## see https://strimzi.io/docs/operators/master/using.html#deploying-cluster-operator-helm-chart-str
helm repo add strimzi https://strimzi.io/charts/

helm install strimy strimzi/strimzi-kafka-operator    -n kafka --set watchAnyNamespace=true
kubectl create clusterrolebinding strimzi-cluster-operator-namespaced --clusterrole=strimzi-cluster-operator-namespaced --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-entity-operator-delegation --clusterrole=strimzi-entity-operator --serviceaccount kafka:strimzi-cluster-operator
kubectl create clusterrolebinding strimzi-cluster-operator-topic-operator-delegation --clusterrole=strimzi-topic-operator --serviceaccount kafka:strimzi-cluster-operator
kubectl set env deployment strimzi-cluster-operator STRIMZI_NAMESPACE="*" 
kafkaversion="0.18.0"
kubectl apply -f https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/$kafkaversion/examples/kafka/kafka-persistent.yaml
