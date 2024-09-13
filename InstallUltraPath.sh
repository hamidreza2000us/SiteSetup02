wget https://satellite.idm.mci.ir/pub/RHEL/Linux/3parties/OceanStor_UltraPath_21.5.0_RHEL.zip
sed -i 's/7.9/7.6/' /etc/redhat-release
unzip OceanStor_UltraPath_21.5.0_RHEL.zip
cd RHEL/
bash install.sh -f unattend_install.conf
#sed -i 's/7.6/7.9/' /etc/redhat-release
#upadmin show vlun
#restart system
echo "the server needs to be restarted"
