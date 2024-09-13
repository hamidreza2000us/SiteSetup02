oc create namespace travel-agency
oc create namespace travel-portal
oc create namespace travel-control

oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_agency.yaml) -n travel-agency
oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_portal.yaml) -n travel-portal
oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travel_control.yaml) -n travel-control

oc label project travel-agency istio-injection=enabled
oc label project travel-portal istio-injection=enabled

oc rollout restart deploy -n travel-portal
oc rollout restart deploy -n travel-agency

oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travels-v2.yaml) -n travel-agency
oc apply -f <(curl -L https://raw.githubusercontent.com/kiali/demos/master/travels/travels-v3.yaml) -n travel-agency