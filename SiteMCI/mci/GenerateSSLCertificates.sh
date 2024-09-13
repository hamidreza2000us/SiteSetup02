
if ([  -z ${automated} ] || [ "${automated}" != 'true' ])
then

	genMethod=1
	domain=mci.ir
	subdomain=siebel01
	keystorepass=qaz@1234
	keypass=qaz@1234
	cakeypass=qaz@1234
	cakeypass=qaz@1234
	###
	keystoredir='/etc/pki/tls/certs'
	#keystoredir='/root/chaintest'
	validcertfile='/root/1400.pfx'
	chaincertfile='/root/chain.pem'
	#vip=172.20.29.148
	cadminPass="Iahoora@123"
	
	echo -e " 1) Private CA \n 2) FreeIPA \n 3) Signed Certificate"
	read -rp "Which method is desired for generate new certificate ($genMethod): " choice; [[ -n "${choice}"  ]] &&  export genMethod="$choice";

	read -rp "What is the domain name : ($domain) " choice; [[ -n "${choice}"  ]] &&  export domain="$choice";
	read -rp "What is the subdomain name : ($subdomain) " choice; [[ -n "${choice}"  ]] &&  export subdomain="$choice";
	read -rp "What is the keyPass for private keys : ($keypass) " choice; [[ -n "${choice}"  ]] &&  export keypass="$choice";
	read -rp "What is the CA keyPass for CA private keys : ($cakeypass) " choice; [[ -n "${choice}"  ]] &&  export cakeypass="$choice";
	read -rp "What is the KeyStore Password : ($keystorepass) " choice; [[ -n "${choice}"  ]] &&  export keystorepass="$choice";
	read -rp "What is the desired location to save files : ($keystoredir) " choice; [[ -n "${choice}"  ]] &&  export keystoredir="$choice";
	read -rp "What is the VIP assigned to ${subdomain}.${domain} to create DNS Record  : ($vip) " choice; [[ -n "${choice}"  ]] &&  export vip="$choice";

	case $genMethod in
	2)
		read -rp "Please Specify Cadmin password of FreeIPA  : ($cadminPass) " choice; [[ -n "${choice}"  ]] &&  export cadminPass="$choice";
		echo "export vip=\"${vip}\"" >> /tmp/values
		echo "export cadminPass=\"${cadminPass}\"" >> /tmp/values
		;;
	3)
		echo "IMPORTANT"
		echo "#############################################"
		echo "YOU SHOULD FIRST COPY THE VALID CERTIFICATE AND CHAIN FILE TO THIS SERVER"
		echo "#############################################"
		read -rp "Please specify the full path of the signed key file : ($validcertfile) " choice; [[ -n "${choice}"  ]] &&  export validcertfile="$choice";
		echo "export validcertfile=\"${validcertfile}\"" >> /tmp/values
		read -rp "Please specify the full path of the Chain certs, if needed : ($chaincertfile) " choice; [[ -n "${choice}"  ]] &&  export chaincertfile="$choice";

		;;
	esac	
	echo "export genMethod=\"${genMethod}\"" >> /tmp/values
	echo "export domain=\"${domain}\"" >> /tmp/values
	echo "export subdomain=\"${subdomain}\"" >> /tmp/values
	echo "export keypass=\"${keypass}\"" >> /tmp/values
	echo "export cakeypass=\"${cakeypass}\"" >> /tmp/values
	echo "export keystorepass=\"${keystorepass}\"" >> /tmp/values
	echo "export keystoredir=\"${keystoredir}\"" >> /tmp/values
	
fi
echo "$vip ${subdomain}.${domain} ${subdomain}" >> /etc/hosts
echo "export keystorepass=\"${keystorepass}\"" > /tmp/values.exported
echo "export keystoredir=\"${keystoredir}\"" >> /tmp/values.exported
chmod +x /tmp/values.exported

mkdir -p ${keystoredir}
yum -y install java-1.8.0-openjdk-devel openssl 

case $genMethod in
  1)
    #generate cakey.pem  careq.pem , the key is private key of ca and req is public key and req for ca
	openssl   req -new -subj "/C=IR/ST=IR/L=Tehran/O=Behsa/OU=Ims/CN=${domain}" -keyout ${keystoredir}/prvca.key -out ${keystoredir}/prvcacrt.pem -passout pass:${cakeypass}
	#openssl rsa  -in CA/cakey.pem -text
	#openssl req  -in CA/careq.pem -text

	#generate caroot.cer ; it generate a certificate using prviate key for ca and there is no signing from another ca
	openssl   x509 -req -in ${keystoredir}/prvcacrt.pem -days 3650 -signkey ${keystoredir}/prvca.key  -out ${keystoredir}/prvcacrt.cer -passin pass:${cakeypass}
	#openssl x509 -in CA/caroot.cer -text

	#import caroot.cer to keystore
	keytool    -import -trustcacerts -alias ca -file ${keystoredir}/prvcacrt.cer  -keystore ${keystoredir}/truststore.jks -keypass ${cakeypass} -storepass ${keystorepass} -noprompt
	
	#generate key pairs and req
	openssl   req -new -subj "/C=IR/ST=IR/L=Tehran/O=Behsa/OU=Ims/CN=${subdomain}.${domain}" -keyout ${keystoredir}/${subdomain}.${domain}.key -out ${keystoredir}/${subdomain}.${domain}.pem -passout pass:${keypass}
	#sign the req with ca

	serial=$( date +"%Y%m%d")
	echo ${serial} > ${serial}
	openssl   x509 -req -CA ${keystoredir}/prvcacrt.cer -CAkey ${keystoredir}/prvca.key -CAserial ${serial} -days 365  -in ${keystoredir}/${subdomain}.${domain}.pem -out ${keystoredir}/${subdomain}.${domain}.cer -passin pass:${cakeypass}
	#openssl verify -CAfile ${keystoredir}/prvcacrt.cer  ${keystoredir}/${subdomain}.${domain}.cer
    keytool    -import -trustcacerts -alias ${subdomain}.${domain}.cer -file ${keystoredir}/${subdomain}.${domain}.cer -keystore ${keystoredir}/truststore.jks  -storepass ${keystorepass} -noprompt

	;;
  2)
    
	echo ${cadminPass} | kinit cadmin
    keytool -alias ca  -import -trustcacerts -noprompt -file /etc/ipa/ca.crt  -keystore ${keystoredir}/truststore.jks -keypass ${keypass} -storepass ${keystorepass}
	ipa host-add ${subdomain}.${domain} --ip-address=${vip}
	ipa service-add HTTP/${subdomain}.${domain}
	ipa service-add-host --hosts $(hostname) HTTP/${subdomain}.${domain}
	ipa-getcert request -D ${subdomain}.${domain}  -f ${keystoredir}/${subdomain}.${domain}.cer  -k ${keystoredir}/${subdomain}.${domain}.key -K HTTP/${subdomain}.${domain} -N "CN=${subdomain}.${domain}"

	sleep 2
	ipa-getcert list
    ;;
  3)
    #to convert der format to pem. the problem here is der contains only one cert so no good choice for chain
	#download the chain from another source or use a different method to extract chain!
	#openssl x509 -inform der  -in Chain.cer -out Chain.pem
	certcount=$(grep -e "-----BEGIN CERTIFICATE-----" ${chaincertfile} | wc -l)
	for index in $(seq 1 $certcount);
	do     
	  awk "/-----BEGIN CERTIFICATE-----/{i++}i==$index" ${chaincertfile} > siebelchain-$index.crt;  
    done
	for i in $(ls siebelchain-*.crt 2> /dev/null )
	do
	    keytool -alias $( basename -s .crt $i)  -import -trustcacerts -noprompt -file $i  -keystore ${keystoredir}/truststore.jks -keypass ${keypass} -storepass ${keystorepass}
		rm -rf $i
	done
    ##keytool -importkeystore -alias ca-trust -srckeystore ${validcertfile} -srcstorepass ${cakeypass} -srcstoretype PKCS12 -destkeystore ${keystoredir}/keystore.jks -deststorepass ${keystorepass}
	openssl pkcs12 -in ${validcertfile} -passin pass:${cakeypass} -nocerts  -passout pass:${keypass} | sed -ne '/-BEGIN ENCRYPTED PRIVATE KEY-/,/-END ENCRYPTED PRIVATE KEY-/p' > ${keystoredir}/${subdomain}.${domain}.key
	#openssl pkcs12 -in ${validcertfile} -passin pass:${cakeypass} -cacerts -nokeys -chain | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  > ${keystoredir}/${domain}ca-chain.cer
	openssl pkcs12 -in ${validcertfile} -passin pass:${cakeypass}  -nokeys -clcerts | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  > ${keystoredir}/${subdomain}.${domain}.cer
    keytool -alias  $( basename  ${keystoredir}/${subdomain}.${domain}.cer)  -import -trustcacerts -noprompt -file  ${keystoredir}/${subdomain}.${domain}.cer  -keystore ${keystoredir}/truststore.jks -keypass ${keypass} -storepass ${keystorepass}

	;;
  *)
    #to convert der format to pem. the problem here is der contains only one cert so no good choice for chain
	#download the chain from another source or use a different method to extract chain!
	#openssl x509 -inform der  -in Chain.cer -out Chain.pem
	certcount=$(grep -e "-----BEGIN CERTIFICATE-----" ${chaincertfile} | wc -l)
	for index in $(seq 1 $certcount);
	do     
	  awk "/-----BEGIN CERTIFICATE-----/{i++}i==$index" ${chaincertfile} > siebelchain-$index.crt;  
    done
	for i in $(ls siebelchain-*.crt 2> /dev/null )
	do
	    keytool -alias $( basename -s .crt $i)  -import -trustcacerts -noprompt -file $i  -keystore ${keystoredir}/truststore.jks -keypass ${keypass} -storepass ${keystorepass}
		rm -rf $i
	done
    ##keytool -importkeystore -alias ca-trust -srckeystore ${validcertfile} -srcstorepass ${cakeypass} -srcstoretype PKCS12 -destkeystore ${keystoredir}/keystore.jks -deststorepass ${keystorepass}
	openssl pkcs12 -in ${validcertfile} -passin pass:${cakeypass} -nocerts  -passout pass:${keypass} | sed -ne '/-BEGIN ENCRYPTED PRIVATE KEY-/,/-END ENCRYPTED PRIVATE KEY-/p' > ${keystoredir}/${subdomain}.${domain}.key
	#openssl pkcs12 -in ${validcertfile} -passin pass:${cakeypass} -cacerts -nokeys -chain | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  > ${keystoredir}/${domain}ca-chain.cer
	openssl pkcs12 -in ${validcertfile} -passin pass:${cakeypass}  -nokeys -clcerts | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  > ${keystoredir}/${subdomain}.${domain}.cer
    keytool -alias  $( basename  ${keystoredir}/${subdomain}.${domain}.cer)  -import -trustcacerts -noprompt -file  ${keystoredir}/${subdomain}.${domain}.cer  -keystore ${keystoredir}/truststore.jks -keypass ${keypass} -storepass ${keystorepass}

	;;
esac

#these will import the key and cert to keystore. Above was to prepare the keys/certs and make truststore
#keytool -import -file  ${keystoredir}/${subdomain}.${domain}.cer -alias ses -keystore ${keystoredir}/keystore.jks -keypass ${keypass} -storepass ${keystorepass} 
openssl pkcs12 -export -in ${keystoredir}/${subdomain}.${domain}.cer -inkey ${keystoredir}/${subdomain}.${domain}.key -name ${subdomain}.${domain} -out ${keystoredir}/${subdomain}.${domain}.p12 -passin pass:${keypass}  -passout  pass:${keypass}
keytool -importkeystore -deststorepass ${keystorepass} -destkeystore ${keystoredir}/keystore.jks -srckeystore ${keystoredir}/${subdomain}.${domain}.p12 -srcstorepass ${keystorepass} -srcstoretype PKCS12 
keytool -import -trustcacerts -alias ca -file ${keystoredir}/${subdomain}.${domain}.cer  -keystore ${keystoredir}/keystore.jks -keypass ${keypass} -storepass ${keystorepass} -noprompt

#Now test the .jks file :
keytool -list -keystore ${keystoredir}/keystore.jks -storepass ${keystorepass} 
keytool -list -keystore ${keystoredir}/truststore.jks -storepass ${keystorepass} 

#keytool -importkeystore  -srckeystore ${keystoredir}/keystore.jks -srcstorepass ${keystorepass} -srckeypass ${cakeypass} -srcalias ses  -destkeystore keystore.p12  -deststoretype PKCS12  -deststorepass ${keystorepass} 
#openssl pkcs12 -in keystore.p12  -nokeys -out cert.pem
#openssl x509  -in cert.pem -text
##openssl pkcs12 -in keystore.p12   -out cert.pem -nodes  -nocerts
##openssl rsa  -in cert.pem -text
