hammer product create --organization-id 1 --name OpenStack13

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat Satellite Tools 6.8 (for RHEL 7 Server) (RPMs) x86_64" \
--url https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/sat-tools/6.8/os/
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Satellite Tools 6.8 (for RHEL 7 Server) (RPMs) x86_64" --async

hammer repository create --product OpenStack13 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat OpenStack Platform 13 for RHEL 7 (RPMs)" \
--url https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/openstack/13/os/ 
hammer repository sync --organization-id 1 --product OpenStack13 --name "Red Hat OpenStack Platform 13 for RHEL 7 (RPMs)" --async

hammer repository create --product OpenStack13 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat Ceph Storage OSD 3 for Red Hat Enterprise Linux 7 Server (RPMs)" \
--url  https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/ceph-osd/1.3/os/
hammer repository sync --organization-id 1 --product OpenStack13 --name "Red Hat Ceph Storage OSD 3 for Red Hat Enterprise Linux 7 Server (RPMs)" --async

hammer repository create --product OpenStack13 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat Ceph Storage MON 3 for Red Hat Enterprise Linux 7 Server (RPMs)" \
--url  https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/ceph-mon/1.3/os/
hammer repository sync --organization-id 1 --product OpenStack13 --name "Red Hat Ceph Storage MON 3 for Red Hat Enterprise Linux 7 Server (RPMs)" --async

hammer repository create --product OpenStack13 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat Ceph Storage Tools 3 for Red Hat Enterprise Linux 7 Server (RPMs)" \
--url  https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/ceph-tools/1.3/os/
hammer repository sync --organization-id 1 --product OpenStack13 --name "Red Hat Ceph Storage Tools 3 for Red Hat Enterprise Linux 7 Server (RPMs)" --async

hammer repository create --product OpenStack13 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat OpenStack 13 Director Deployment Tools for RHEL 7 (RPMs)" \
--url  https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/openstack-deployment-tools/13/os/
hammer repository sync --organization-id 1 --product OpenStack13 --name "Red Hat OpenStack 13 Director Deployment Tools for RHEL 7 (RPMs)" --async

hammer repository create --product RH7 --content-type yum --download-policy immediate --mirror-on-sync no \
--organization-id 1 --name "Red Hat Enterprise Linux 7 Server - Optional (RPMs)" \
--url  https://satellite.idm.mci.ir/pub/RHEL/content/dist/rhel/server/7/7Server/x86_64/optional/os/
hammer repository sync --organization-id 1 --product RH7 --name "Red Hat Enterprise Linux 7 Server - Optional (RPMs)" --async

hammer content-view create --name OpenStack13 --label OpenStack13 --organization-id 1 
hammer content-view add-repository --name  OpenStack13  --product OpenStack13 --organization-id 1 --repository "Red Hat OpenStack Platform 13 for RHEL 7 (RPMs)"
hammer content-view add-repository --name  OpenStack13  --product OpenStack13 --organization-id 1 --repository "Red Hat Ceph Storage OSD 3 for Red Hat Enterprise Linux 7 Server (RPMs)"
hammer content-view add-repository --name  OpenStack13  --product OpenStack13 --organization-id 1 --repository "Red Hat Ceph Storage MON 3 for Red Hat Enterprise Linux 7 Server (RPMs)"
hammer content-view add-repository --name  OpenStack13  --product OpenStack13 --organization-id 1 --repository "Red Hat Ceph Storage Tools 3 for Red Hat Enterprise Linux 7 Server (RPMs)"
hammer content-view add-repository --name  OpenStack13  --product OpenStack13 --organization-id 1 --repository "Red Hat OpenStack 13 Director Deployment Tools for RHEL 7 (RPMs)"
hammer content-view add-repository --name  OpenStack13  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server"
hammer content-view add-repository --name  OpenStack13  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux 7 Server - Extras RPMs x86_64"
hammer content-view add-repository --name  OpenStack13  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server"
hammer content-view add-repository --name  OpenStack13  --product RH7 --organization-id 1 --repository "Red Hat Satellite Tools 6.8 (for RHEL 7 Server) (RPMs) x86_64"
hammer content-view add-repository --name  OpenStack13  --product RH7 --organization-id 1 --repository "Red Hat Enterprise Linux High Availability for RHEL 7 Server RPMs x86_64 7Server"

hammer content-view publish --name OpenStack13 --organization-id 1 --async
hammer activation-key create --name OpenStack13 --organization-id 1 --lifecycle-environment Library --content-view OpenStack13
hammer activation-key update --name OpenStack13 --auto-attach false --organization-id 1
subsID=$(hammer --output csv --no-headers  subscription list | grep ",OpenStack13," | awk -F, '{print $1}')
hammer activation-key add-subscription --name OpenStack13 --subscription-id ${subsID}  --organization-id 1