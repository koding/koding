## Bluemix Container Service

To run tests that require a Kubernetes in-cluster environment on the Bluemix
Container Service follow these steps:

### 1 - Bluemix account & provisioned Kubernetes cluster
You need a Bluemix account, and should be able to use a free-trial account
if you don't have one. Go [here](https://console.ng.bluemix.net) either way
and get logged in, then follow directions [here](https://console.ng.bluemix.net/docs/containers/container_index.html)
to get a Kubernetes cluster provisioned.

### 2 - Setup kubectl
Setup your local `kubectl` to interact with your provisioned K8s cluster by
following [these](https://console.ng.bluemix.net/docs/containers/cs_cli_install.html#cs_cli_install)
instructions. You should be able to run `kubectl get nodes` successfully!

> NOTE: Can use Docker to run kubectl by mounting client artifacts located
> at `kubectl cluster-config` into the `acbodine/kubectl` image on DockerHub.

### 3 - Provision the testing Kubernetes pod
The provided `test-klient.yaml` pod spec should be used to establish the testing environment the current
proxy test cases expect for Kubernetes.
```
$ kubectl apply -f go/src/koding/klient/proxy/test-klient.yaml
```

### 4 - Run tests
To actually run the tests, we need to move them to the `klient` container in the `test-klient` pod that we just provisioned:
```
$ kubectl exec koding -c klient -it bash
root@koding:/opt/kite/klient# cd workspace
root@koding:/opt/kite/klient# git clone -b klient-proxy https://github.com/acbodine/koding
root@koding:/opt/kite/klient# export GOPATH=/opt/kite/klient/workspace/koding/go
root@koding:/opt/kite/klient# go test -v koding/klient/proxy
```
