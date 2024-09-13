###
#tested on RHEL7
#This script configure a vnc session for user root with password ahoora on port 5900 (:0)
#you can check if the port is up by lsof -Pi :5900
#the quality of the vnc is lower comare to xdmcp but it is faster and doesn't require much network port access
yum install tigervnc-server
cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@:0.service
sed -i "s/<USER> %i/root %i/g"  /etc/systemd/system/vncserver@:0.service
systemctl daemon-reload;
systemctl enable vncserver@:0.service 
systemctl restart vncserver@:0.service 
systemctl status vncserver@:0.service
echo ahoora | vncpasswd -f > /root/.vnc/passwd
#you may need to change the permission of vnc/passwd file if running for other user or simply use vncpasswd
firewall-cmd --add-service=vnc-server --permanent
firewall-cmd --reload