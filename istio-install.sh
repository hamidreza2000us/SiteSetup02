
mkdir ~/istio
tee ~/istio/elastic-sub.yml &>/dev/null <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elasticsearch-operator
  namespace: openshift-operators
spec:
  channel: "stable-5.8" 
  name: elasticsearch-operator 
  source: redhat-operators 
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF
oc apply -f istio/elastic-sub.yml
#openshift-operators-redhat

tee ~/istio/jaeger-sub.yml &>/dev/null <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: jaeger-product
  namespace: openshift-operators
spec:
  name: jaeger-product
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  channel: "stable"
  installPlanApproval: Automatic
EOF
oc apply -f istio/jaeger-sub.yml



tee ~/istio/kiali-sub.yml &>/dev/null <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: kiali-ossm
  namespace: openshift-operators
spec:
  name: kiali-ossm
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  channel: "stable"
  installPlanApproval: Automatic
EOF
oc apply -f istio/kiali-sub.yml



tee ~/istio/servicemesh-sub.yml &>/dev/null <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: 'stable'
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  installPlanApproval: Automatic
EOF
oc apply -f istio/servicemesh-sub.yml


oc get  subscriptions.operators.coreos.com -n openshift-operators
################

oc new-project istio-system

tee ~/istio/SM-CM.yml &>/dev/null <<EOF
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic 
  namespace: istio-system 
spec:
  gateways: 
    egress:
      enabled: true
      runtime:
        deployment:
          autoScaling:
            enabled: false
    ingress:
      enabled: true
      runtime:
        deployment:
          autoScaling:
            enabled: false

  tracing: 
    sampling: 10000
    type: Jaeger

  telemetry:
    type: Istiod
  version: v2.5
  
  policy:
    type: Istiod

  addons:
    grafana: 
      enabled: true
    jaeger: 
      install:
        storage:
          type: Memory
    kiali: 
      enabled: true
	prometheus:
      enabled: true
EOF
oc apply -f istio/SM-CM.yml

oc get -w ServiceMeshControlPlane -n istio-system

################################
tee ~/istio/smmr.yml &>/dev/null <<EOF
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: istio-system
spec:
  members:
EOF
oc apply -f ~/istio/smmr.yml


#############################
tee ~/istio/add-project-to-smmr.sh &>/dev/null <<'EOF'
#!/bin/bash
ns=$(echo $1 | tr -d "'")
#echo $ns
#oc get smmr -n istio-system -o json | jq .items[0].spec.members
oc patch servicemeshmemberroll/default -n istio-system --type=merge -p '{"spec": {"members":["'$ns'"]}}'
EOF


bash ~/istio/add-project-to-smmr.sh bookinfo
oc get smmr -n istio-system -o wide
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.5/samples/bookinfo/platform/kube/bookinfo.yaml
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.5/samples/bookinfo/networking/bookinfo-gateway.yaml
export GATEWAY_URL=$(oc -n istio-system get route istio-ingressgateway -o jsonpath='{.spec.host}')
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.5/samples/bookinfo/networking/destination-rule-all.yaml

#oc -n istio-system patch --type='json' smmr default -p '[{"op": "remove", "path": "/spec/members", "value":["'"bookinfo"'"]}]'
#oc patch deployment/<deployment> -p '{"spec":{"template":{"metadata":{"annotations":{"kubectl.kubernetes.io/restartedAt": "'`date -Iseconds`'"}}}}}'

tee ~/istio/add-sidecar-to-deploy.sh &>/dev/null <<'EOF'
#!/bin/bash
ns=$(echo $1 | tr -d "'")
while read line
do
  deploy=$(echo $line | tr -d "'")
  oc patch deploy $deploy -n $ns -p '{"spec":{"template":{"metadata":{"labels":{ "sidecar.istio.io/inject": "true"}}}}}'
  oc rollout restart deployment $deploy  -n $ns
done< <(oc get deploy -n $ns -o custom-columns=NAME:metadata.name | tail -n +2)
EOF
#############################

#sidecar.istio.io/inject: "true"

wget https://github.com/istio/istio/releases/download/1.22.2/istio-1.22.2-linux-amd64.tar.gz
tar -xvf istio-1.22.2-linux-amd64.tar.gz
cp istio-1.22.2/bin/istioctl /bin/
sudo chmod o+x /usr/bin/istioctl
istioctl completion bash >  /tmp/istio.sh
chmod +x /tmp/istio.sh
sudo mv /tmp/istio.sh /etc/bash_completion.d/ ;
echo 'source /etc/bash_completion.d/istio.sh' >> ~/.bashrc ;
source /etc/bash_completion.d/istio.sh

oc -n istio-system get configmap istio-sidecar-injector-basic -o=jsonpath='{.data.config}' > inject-config.yaml
oc -n istio-system get configmap istio-sidecar-injector-basic -o=jsonpath='{.data.values}' > inject-values.yaml
oc -n istio-system get configmap istio-basic -o=jsonpath='{.data.mesh}' > mesh-config.yaml
oc get deployment -o yaml | istioctl kube-inject --injectConfigFile inject-config.yaml --meshConfigFile mesh-config.yaml --valuesFile inject-values.yaml -f - | oc apply -f -

oc label namespace mytest01 istio-injection=enabled --overwrite
#oc label namespace mytest01 istio-injection-




###################################
oc create namespace travel-agency
oc create namespace travel-portal
oc create namespace travel-control

oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_agency.yaml) -n travel-agency
oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_portal.yaml) -n travel-portal
oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_control.yaml) -n travel-control
bash ~/istio/add-sidecar-to-deploy.sh travel-agency
bash ~/istio/add-sidecar-to-deploy.sh travel-control
bash ~/istio/add-sidecar-to-deploy.sh travel-portal




oc delete -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_agency.yaml) -n travel-agency
oc delete -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_portal.yaml) -n travel-portal
oc delete -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_control.yaml) -n travel-control
oc delete project travel-portal
oc delete project travel-agency
oc delete project travel-control





oc label project travel-agency istio-injection=enabled
oc label project travel-portal istio-injection=enabled

oc rollout restart deploy -n travel-portal
oc rollout restart deploy -n travel-agency

oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travels-v2.yaml) -n travel-agency
oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travels-v3.yaml) -n travel-agency