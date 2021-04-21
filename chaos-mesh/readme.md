unning 'File Create' participants...


curl -sSL https://mirrors.chaos-mesh.org/v1.1.2/install.sh | bash

kubectl get pod -n chaos-testing


## container d 
https://chaos-mesh.org/docs/user_guides/installation/
## install repo
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm search repo chaos-mesh
## install crd 
curl -sSL https://mirrors.chaos-mesh.org/v1.1.3/crd.yaml | kubectl apply -f -

kubectl create ns chaos-testing
helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock --set dashboard.create=true --set rbac.create=true --set dashboard.securityMode=false
helm upgrade chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-testing --set dashboard.securityMode=false --set dashboard.create=true

kubectl port-forward -n chaos-testing svc/chaos-dashboard 2333:2333


## uninstall 
curl -sSL https://mirrors.chaos-mesh.org/v1.1.3/install.sh | bash -s -- --template | kubectl delete -f -
