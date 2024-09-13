domain=mci.ir
subdomain=siebel01
keystorepassp=qaz@1234
keypass=qaz@1234
cakeypass=%M30%i20@N0AuthF@1400
#keystoredir='/etc/pki/tls/certs'
keystoredir='/root/catest2'
validcertfile=mcicert.pfx
#if no ca create ca
	#generate cakey.pem  careq.pem , the key is private key of ca and req is public key and req for ca
	openssl   req -new -subj "/C=IR/ST=IR/L=Tehran/O=Behsa/OU=Ims/CN=${domain}" -keyout ${keystoredir}/prvca.key -out ${keystoredir}/prvcacrt.pem -passout pass:${cakeypass}
	#openssl rsa  -in CA/cakey.pem -text
	#openssl req  -in CA/careq.pem -text

	#generate caroot.cer ; it generate a certificate using prviate key for ca and there is no signing from another ca
	openssl   x509 -req -in ${keystoredir}/prvcacrt.pem -days 3650 -extensions v3_ca -signkey ${keystoredir}/prvca.key  -out ${keystoredir}/prvcacrt.cer -passin pass:${cakeypass}
	#openssl x509 -in CA/caroot.cer -text

	#import caroot.cer to keystore
	keytool    -import -trustcacerts -alias ca -file ${keystoredir}/prvcacrt.cer  -keystore ${keystoredir}/keystore.jks -keypass ${cakeypass} -storepass ${keystorepassp} -noprompt
	
	#generate key pairs and req
	openssl   req -new -subj "/C=IR/ST=IR/L=Tehran/O=Behsa/OU=Ims/CN=${subdomain}.${domain}" -keyout ${keystoredir}/${subdomain}.${domain}.key -out ${keystoredir}/${subdomain}.${domain}.pem -passout pass:${keypass}
	#sign the req with ca

	serial=$( date +"%Y%m%d")
	echo ${serial} > ${serial}
	openssl   x509 -req -CA ${keystoredir}/prvcacrt.cer -CAkey ${keystoredir}/prvca.key -CAserial ${serial} -days 365  -in ${keystoredir}/${subdomain}.${domain}.pem -out ${keystoredir}/${subdomain}.${domain}.cer -passin pass:${cakeypass}
	#openssl verify -CAfile ${keystoredir}/prvcacrt.cer  ${keystoredir}/${subdomain}.${domain}.cer
#else if idm certificate
	echo "Iahoora@1234" | kinit cadmin
    vip=172.20.29.144
	subdomain=siebel03
	ipa host-add ${subdomain}.${domain} --ip-address=${vip}
	ipa service-add HTTP/${subdomain}.${domain}
	ipa service-add-host --hosts $(hostname) HTTP/${subdomain}.${domain}
	ipa-getcert request -D ${subdomain}.${domain}  -f ${keystoredir}/${subdomain}.${domain}.pem  -k ${keystoredir}/${subdomain}.${domain}.key -K HTTP/${subdomain}.${domain} -N "CN=${subdomain}.${domain}"
	ipa-getcert list

#else valid certificate
   #openssl x509 -inform der  -in Chain.cer -out Chain.pem
   ##keytool -importkeystore -alias ca-trust -srckeystore ${keystoredir}/${validcertfile} -srcstorepass ${cakeypass} -srcstoretype PKCS12 -destkeystore ${keystoredir}/keystore.jks -deststorepass ${keystorepassp}
	#extra work may needed to import the chain to the keystore or extract key from pfx
	openssl pkcs12 -in ${keystoredir}/${validcertfile} -passin pass:${cakeypass} -nocerts  -passout pass:${keypass} | sed -ne '/-BEGIN ENCRYPTED PRIVATE KEY-/,/-END ENCRYPTED PRIVATE KEY-/p' > ${keystoredir}/${subdomain}.${domain}.key
	#openssl pkcs12 -in ${keystoredir}/${validcertfile} -passin pass:${cakeypass} -cacerts -nokeys -chain | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  > ${keystoredir}/${domain}ca-chain.cer
	openssl pkcs12 -in ${keystoredir}/${validcertfile} -passin pass:${cakeypass}  -nokeys -clcerts | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'  > ${keystoredir}/${subdomain}.${domain}.cer

#import the certificate and key
	#import ses.cer to keystore
	keytool    -import  -file  ${keystoredir}/${subdomain}.${domain}.cer -alias ses -keystore ${keystoredir}/keystore.jks -keypass ${keypass} -storepass ${keystorepassp} 
	openssl pkcs12 -export -in ${keystoredir}/${subdomain}.${domain}.cer -inkey ${keystoredir}/${subdomain}.${domain}.key -name ${subdomain}.${domain} -out ${keystoredir}/${subdomain}.${domain}.p12 -passin pass:${keypass} -passout  pass:${keypass}
	keytool  -importkeystore -deststorepass ${keystorepassp} -destkeystore ${keystoredir}/keystore.jks -srckeystore ${keystoredir}/${subdomain}.${domain}.p12 -srcstorepass ${keystorepassp} -srcstoretype PKCS12 
	#Now test the .jks file :
	keytool -list -keystore ${keystoredir}/keystore.jks -storepass ${keystorepassp} 
	#keytool -importkeystore  -srckeystore ${keystoredir}/keystore.jks -srcstorepass ${keystorepassp} -srckeypass ${cakeypass} -srcalias ses  -destkeystore keystore.p12  -deststoretype PKCS12  -deststorepass ${keystorepassp} 
	#openssl pkcs12 -in keystore.p12  -nokeys -out cert.pem
	#openssl x509  -in cert.pem -text
	##openssl pkcs12 -in keystore.p12   -out cert.pem -nodes  -nocerts
	##openssl rsa  -in cert.pem -text
