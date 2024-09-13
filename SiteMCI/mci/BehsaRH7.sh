PRDName=RH7
SatHost=satellite
Domain=idm.mci.ir

hammer product create --organization-id 6 --name RH7

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 6 --name \
"Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/os
hammer repository sync --organization-id 6 --product RH7 --name "Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 6 --name \
"Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/rh-common/os
hammer repository sync --organization-id 6 --product RH7 --name "Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 6 --name \
"Red Hat Enterprise Linux 7 Server - Extras RPMs x86_64" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/extras/os
hammer repository sync --organization-id 6 --product RH7 --name "Red Hat Enterprise Linux 7 Server - Extras RPMs x86_64" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 6 --name \
"Red Hat Enterprise Linux High Availability for RHEL 7 Server RPMs x86_64 7Server" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/highavailability/os
hammer repository sync --organization-id 6 --product RH7 --name "Red Hat Enterprise Linux High Availability for RHEL 7 Server RPMs x86_64 7Server" --async


hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 6 --name \
"Red Hat Ansible Engine 2.9 RPMs for Red Hat Enterprise Linux 7 Server x86_64" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/ansible/2.8/os
hammer repository sync --organization-id 6 --product RH7 --name "Red Hat Ansible Engine 2.9 RPMs for Red Hat Enterprise Linux 7 Server x86_64" --async

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 6 --name "Red Hat Enterprise Linux 7 Server - Optional (RPMs)" \
--url  https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/optional/os/
hammer repository sync --organization-id 6 --product RH7 --name "Red Hat Enterprise Linux 7 Server - Optional (RPMs)" --async


hammer content-view create --name RH7 --label RH7 --organization-id 6
hammer content-view add-repository --name  RH7  --product RH7 --organization-id 6 --repository "Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server"
hammer content-view add-repository --name  RH7  --product RH7 --organization-id 6 --repository "Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server"
hammer content-view add-repository --name  RH7  --product RH7 --organization-id 6 --repository "Red Hat Enterprise Linux 7 Server - Extras RPMs x86_64"
hammer content-view add-repository --name  RH7  --product RH7 --organization-id 6 --repository "Red Hat Enterprise Linux High Availability for RHEL 7 Server RPMs x86_64 7Server"
hammer content-view add-repository --name  RH7  --product RH7 --organization-id 6 --repository "Red Hat Ansible Engine 2.9 RPMs for Red Hat Enterprise Linux 7 Server x86_64"
hammer content-view add-repository --name  RH7  --product RH7 --organization-id 6 --repository "Red Hat Enterprise Linux 7 Server - Optional (RPMs)"

hammer content-view publish --name RH7 --organization-id 6 --async
hammer activation-key create --name RH7 --organization-id 6 --lifecycle-environment Library --content-view RH7
hammer activation-key update --name RH7 --auto-attach false --organization-id 6
subsID=$(hammer --output csv --no-headers  subscription list --organization-id 6 | grep ",RH7," | awk -F, '{print $1}')
hammer activation-key add-subscription --name RH7 --subscription-id ${subsID}  --organization-id 6





SatHost=satellite
Domain=idm.mci.ir
release=7.9
#########################network config##################

hammer lifecycle-environment create  --description "dev"  --name dev  --label dev --organization-id 6 --prior Library
hammer lifecycle-environment create  --description "qa"  --name qa  --label qa --organization-id 6 --prior dev
hammer lifecycle-environment create  --description "prod"  --name prod  --label prod --organization-id 6 --prior qa

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no --organization-id 6 \
--name "Red Hat Enterprise Linux 7 Server Kickstart ${release}" --url http://${SatHost}.${Domain}/pub/RHEL/content/dist/rhel/server/7/7.9/x86_64/kickstart/
hammer repository sync --organization-id 6 --product RH7 --name "Red Hat Enterprise Linux 7 Server Kickstart ${release}" --async 

hammer content-view add-repository --name vrh7  --organization-id 6 --repository "Red Hat Enterprise Linux 7 Server Kickstart ${release}"
hammer content-view publish --name vrh7 --organization-id 6 

##########################test#################################
hammer activation-key create --name krh7 --organization-id 6 --lifecycle-environment Library --content-view vrh7
hammer activation-key update --name krh7 --auto-attach false --organization-id 6
subsID=$(hammer --output csv --no-headers  subscription list | grep ",RH," | awk -F, '{print $1}')
#id=$( hammer activation-key add-subscription --name krh7 --subscription-id ${subsID}  --organization-id 6)
hammer activation-key add-subscription --name krh7 --subscription-id ${subsID}  --organization-id 6


hammer hostgroup create --name HRH7 --parent HGBareMetal --operatingsystem "RedHat ${release}" --content-view vrh7 --organization-id 6
hammer hostgroup set-parameter --hostgroup HGPCeph4  --name kt_activation_keys --parameter-type string --value krh7

