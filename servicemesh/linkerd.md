## install 
 see https://linkerd.io/2/getting-started/

 * curl -sL https://run.linkerd.io/install | sh
 * export PATH=$PATH:$HOME/.linkerd2/bin
 * linkerd install | kubectl apply -f -


## expose Dashboard 

linkerd dashboard &


##  Deploy Book app 
kubectl create ns booksapp && \
  curl -sL https://run.linkerd.io/booksapp.yml \
  | kubectl -n booksapp apply -f -

* check status 
kubectl -n booksapp rollout status deploy webapp

* expose application 
kubectl -n booksapp port-forward svc/webapp 7000 &


## Add linkerd to Services 
kubectl get -n booksapp deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -


kubectl get -n prod deploy -o yaml  | linkerd inject -   | kubectl apply -f -

## Expose linkerd dashboard 
linkerd dashboard &
 

kubectl -n emojivoto port-forward svc/web-svc 8080:80 
export PATH=$PATH:$HOME/.linkerd2/bin


kubectl get -n emojivoto deploy -o yaml \
  | linkerd inject - \
  | kubectl apply -f -




### remove 
kubectl get -n prod deploy -o yaml  | linkerd uninject -   | kubectl apply -f -




## install 
 curl -sL run.linkerd.io/install | sh
 linkerd viz install | kubectl apply -f -
kubectl get -n prod deploy -o yaml  | linkerd uninject -   | kubectl apply -f -
kubectl get -n nginx  deploy -o yaml  | linkerd inject -   | kubectl apply -f -
## verify 
linkerd viz stat deployments -n prod
## view dashboard 
linkerd viz dashboard &
kubectl port-forward  service/web -n linkerd-viz 8084:8084
