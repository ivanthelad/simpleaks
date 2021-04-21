 ### install  zoo keeper  operator

 # instal apache solr operators
## Before installing the Solr Operator, we need to install the . zookeeper 
see https://artifacthub.io/packages/helm/apache-solr/solr-operator
see https://github.com/apache/solr-operator#documentation

```
// install zk
kubectl apply -f https://apache.github.io/solr-operator/example/dependencies/zk_operator.yaml
// install solr operator 
 helm repo add apache-solr-op https://solr.apache.org/charts
 helm install solr-operator apache-solr-op/solr-operator
 helm install solr-operator apache-solr-op/solr-operator --namespace solr


 helm repo add apache-solr https://solr.apache.org/charts
// uninstall 


 ```
Once configured we can configre the CRD 
https://apache.github.io/solr-operator/docs/solr-cloud/solr-cloud-crd.html

# another option  with lucene
```

kubectl apply -f https://apache.github.io/lucene-solr-operator/example/dependencies/zk_operator.yaml
helm repo add apache-solr https://apache.github.io/lucene-solr-operator/charts
 helm repo add apache-solr https://solr.apache.org/charts
```

#### zookeeper
install bitnami helm 
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install  my-release bitnami/zookeeper -n solr2 -f zookeeper.yaml

helm upgrade my-release  -n solr2 -f zoookeeper2.yaml


### install using bitnami 
https://bitnami.com/stack/solr/helm

helm repo add bitnami https://charts.bitnami.com/bitnami

helm install my-release bitnami/solr

see installation https://github.com/bitnami/charts/tree/master/bitnami/solr/#installing-the-chart
https://github.com/bitnami/charts/tree/master/bitnami/solr/templates
## download helm chart 
 helm pull bitnami/solr     --destination solr --untar
 ## motivation is to modify the the spread
