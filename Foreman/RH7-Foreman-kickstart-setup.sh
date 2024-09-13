foreman-installer \
--foreman-proxy-dhcp true \
--foreman-proxy-dhcp-interface ens33\
--foreman-proxy-dhcp-managed true \
--foreman-proxy-dhcp-range="192.168.13.50 192.168.13.100" \
--foreman-proxy-dhcp-nameservers 192.168.1.175 \
--foreman-proxy-dhcp-gateway 192.168.13.2 \ 
--foreman-proxy-dns true \
--foreman-proxy-dns-managed true \ 
--foreman-proxy-dns-interface ens33  
--foreman-proxy-dns-zone myhost.com \ 
--foreman-proxy-dns-forwarders 192.168.1.175 \ 
--foreman-proxy-dns-reverse 13.168.192.in-addr.arpa \ 
--foreman-proxy-tftp true \
--foreman-proxy-tftp-managed true \
--foreman-proxy-tftp-servername foreman02.myhost.com 