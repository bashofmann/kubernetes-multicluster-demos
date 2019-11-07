# Two clusters in different regions connected with Wireguard

## Cluster preparation

* Create a cluster in region dbl with CoreOS Nodes
* Create a cluster in region cbk with CoreOS Nodes, with different Node,Pod and Service IP CIDR
* Install wireguard in both
```
kubectl apply -f https://raw.githubusercontent.com/squat/modulus/master/wireguard/daemonset.yaml
```
* Open 51820 in all security groups
* Add force external ip annotation in both
```
bash ../annotate-external-ip.sh
```
* Install kilo to configure Wireguard in dbl
```
kubectl apply -f https://raw.githubusercontent.com/squat/kilo/master/manifests/kilo-kubeadm.yaml
```
* Install kilo to configure Wireguard in cbk and sett this argument
```
- --subnet=10.4.1.0/24
```
```
kubectl apply -f kilo-different-subnet.yaml
```
* Add peers to clusters
```
kubectl apply -f peer-in-cbk.yaml --context cbk
kubectl apply -f peer-in-dbl.yaml --context dbl
```

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
kubectl exec -it -n sample -c sleep $(kubectl get pod -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl POD/SERVICEIPS
```

## Configure internal dns

* Edit coredns and nodelocal dns cache configs:

```
    cluster.cbk:53 {
      forward . 10.10.11.10
    }
    .:53 {
        errors
        health
        kubernetes cluster.local cluster.dbl in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```
```
    cluster.dbl:53 {
        errors
        cache 30
        reload
        loop
        bind 169.254.20.10
        forward . 10.10.11.10 {
                force_tcp
        }
        prometheus :9253
        }
    cluster.cbk:53 {
        errors
        cache 30
        reload
        loop
        bind 169.254.20.10
        forward . 10.10.11.10 {
                force_tcp
        }
        prometheus :9253
        }

```

Test requests

```
kubectl exec -it -n sample -c sleep $(kubectl get pod -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl test-service.test-namespace.svc.cluster.dbl
kubectl exec -it -n sample -c sleep $(kubectl get pod -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}') -- curl test-service.test-namespace.svc.cluster.cbk
```

## Configure external dns

* Create lbs

```
kubectl apply -f kubefed-app-external-dns/federatedlb.yaml
```

* Install external dns
```
helm upgrade --install external-dns --namespace=external-dns -f  kubefed-app-external-dns/external-dns-values.yaml stable/external-dns
```

* Apply multicluster DNS config
```
kubectl apply -f kubefed-app-external-dns/multicluster-dns.yaml
```

* Show DNSEndpoints

```
kubectl get dnsendpoint -o yaml -A
```

* Show zone
```
watch openstack recordset list 62e2b5ee-4c3e-49c4-ba9e-fddf611e55a3
```

* Go to

* http://test-service-lb.test-namespace.test-domain.svc.dbl.multi.metakube.org/
* http://test-service-lb.test-namespace.test-domain.svc.cbk.multi.metakube.org/
* http://test-service-lb.test-namespace.test-domain.svc.multi.metakube.org/