# Two clusters in different regions connected with Istio

## Cluster preparation

* Create a cluster in region dbl with CoreOS Nodes
* Create a cluster in region cbk with CoreOS Nodes, with different Node,Pod and Service IP CIDR

Follow https://istio.io/docs/setup/install/multicluster/shared-gateways/

## Test application

* Install kubefed
```
helm install kubefed-charts/kubefed --name kubefed --namespace kube-federation-system --version 0.1.0-rc6
```
* Join clusters
```
kubefedctl join dbl --cluster-context dbl --host-cluster-context dbl --v=2
kubefedctl join cbk --cluster-context cbk --host-cluster-context dbl --v=2
```
* Install app
```
kubectl apply -f kubefed-app
```
* Install sample app with curl
```
kubectl apply -f curl-app
```

* Test requests
```
kubectl exec -it -n sample -c sleep $(kubectl get pod -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl test-service.test-namespace
```