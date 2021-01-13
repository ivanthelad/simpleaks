

## Demo install istio

## Deploy application 
$ kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

kubectl label namespace default istio-injection=enabled2

loging 
 echo "http://$GATEWAY_URL/productpage"


## expose application to outside world 
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

## fault injection 
Sign in a jason 
##  tunnel to kahli 
istioctl dashboard kiali


Look at destination Rule 
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-svc
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v3
    labels:
      version: v3