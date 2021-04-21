## Install 

kubectl create namespace nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
 helm repo update
helm search repo nginx
kubectl create namespace nginx
helm install my-release ingress-nginx/ingress-nginx --set controller.admissionWebhooks.enabled=false -n nginx --set controller.metrics.serviceMonitor.enabled=true --set controller.metrics.enabled=true

## hlem install 
 helm upgrade  my-release ingress-nginx/ingress-nginx -n nginx -f values.yaml --install

### Modify customer error pages 
you can modfiy the default backend for 404 errors 
https://github.com/kubernetes/ingress-nginx/blob/master/charts/ingress-nginx/values.yaml#L545
if this is confiugured then a custom service will be generated 


### custom pages 
If you wish to send to an existing service you need configure the config. You need to edit the config map 
https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples/customization/custom-errors#ingress-controller-configuration
ingress-nginx-controller and edit the entry custom-http-error


https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples/customization/custom-errors

https://github.com/kubernetes/ingress-nginx/tree/master/docs/examples/customization/custom-errors

--set controller.admissionWebhooks.enabled=false