

# Deploying a zone aware ES With Azure Backups 
## install operator 
* curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.17.0/install.sh | bash -s v0.17.0
or 
* kubectl create -f https://operatorhub.io/install/elastic-cloud-eck.yaml
## Deploy custom storageclass. 
we deploy a custom storage class that sets the following config 
* volumeBindingMode: WaitForFirstConsumer 
this ensure the storage behind ES comes up in the same zone as the pod. 
``` kubectl apply -f storageclass-premium.yaml```

## Create Azrue Storage secret 
the following step is required as we intend to configure backups for our data in the aks. This step creates a secret which will reference
* azure.client.default.account: The storage account name. 
* azure.client.default.key: the key for the storage account. found under keys.

```kubectl create secret generic essecret --from-literal=azure.client.default.account=xxxxx --from-literal=azure.client.default.key=xxxxxx== ```

the above settings are injected into by the operator into the elastic search cluster. in the azure plugin this means there is a client called 'default' that can perform backups. if you wanted to target multiple storage accounts then it would look like this 
* azure.client.default.account: The storage account name. 
* azure.client.default.key: the key for the storage account. found under keys.
* azure.client.otheraccount.account: The storage account name. 
* azure.client.otheraccount.key: the key for the storage account. found under keys.

https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-es-secure-settings.html
https://arunksingh16.medium.com/snapshot-using-azure-repository-plugin-in-elasticsearch-eck-81584b48836a

## Deploy ES 
The custom elastic search resource has the following changes 
* installs azure backup plugin 
* configures custom storage to avail of zones. managed-premium-zoneaware
* configures deployment model ensure even spread across Zones and nodes 
* referecne secret to access azure storage 
``` kubectl apply -f zoneaware_es.yaml```

Note: the affinity and spread model expects 
 * nodes that match a selecto  agentpool=elastic. See  affinity section 
 *  topologySpreadConstraints. Attempts to spread ES pods across zones, but also attempts to spread pods across pods in a zone (if more nodes exsit). if it cannot spread across this topologyy then scheduling will fail 

### base settings 
https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html
https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/


## Deploy kibana 
``` kubectl apply -f zoneaware-kibana.yaml```

this deploys a kibana instance to access the ES. to login to the ES with the user "elastic" 
```kubectl get secret zoneaware-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode; echo```

to view kibana you can tunnel to the endpoint 
``` kubectl port-forward service/zoneaware-kb-http 5601 ```

## To Configure backups go to 
https://arunksingh16.medium.com/snapshot-using-azure-repository-plugin-in-elasticsearch-eck-81584b48836a
https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-snapshots.htm
to configure backups you can tunnel to the endpoint 
``` kubectl port-forward service/zoneaware-kb-http 5601 ``


*** https://arunksingh16.medium.com/snapshot-using-azure-repository-plugin-in-elasticsearch-eck-81584b48836a



