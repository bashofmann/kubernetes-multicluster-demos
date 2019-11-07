# One cluster with nodes in two regions

## Cluster preparation

* Create a cluster in region dbl with CoreOS Nodes

https://dev.metakube.de/projects/hsmgbrmhdj/dc/dbl1/clusters/v6tswzr9td

* Create a network, subnet, router in the other region with a different IP range

```
openstack network create metakube-v6tswzr9td
openstack subnet create metakube-v6tswzr9td --network metakube-v6tswzr9td --subnet-range 192.168.2.0/24 --gateway 192.168.2.1 --dns-nameserver 37.123.105.116 --dns-nameserver 37.123.105.117
openstack router create metakube-v6tswzr9td
openstack port create --network metakube-v6tswzr9td --fixed-ip subnet=metakube-v6tswzr9td,ip-address=192.168.2.1 metakube-v6tswzr9td-gw
openstack router add port metakube-v6tswzr9td metakube-v6tswzr9td-gw
openstack router set metakube-v6tswzr9td --external-gateway ext-net
```

* Create a CoreOS MachineDeployment in the other region
```
kubectl apply -f cross-region-machine-deployment.yaml
```
* Ensure that Node registers itself in Kubernetes
* Install wireguard
```
kubectl apply -f https://raw.githubusercontent.com/squat/modulus/master/wireguard/daemonset.yaml
```
* Open 51820 in all security groups
* Add force external ip annotation
```
bash ../annotate-external-ip.sh
```
* Install kilo to configure Wireguard
```
kubectl apply -f https://raw.githubusercontent.com/squat/kilo/master/manifests/kilo-kubeadm.yaml
```

## Test application

* Deploy app
```
kubectl apply -f 01-one-cluster/app/
```
* Install sample app with curl
```
kubectl apply -f curl-app
```
* Test requests
```
kubectl exec -it -n sample -c sleep $(kubectl get pod -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl POD/SERVICEIPS

kubectl exec -it -n sample -c sleep $(kubectl get pod -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl nginx.default
```