mkdir {CA,keys}
#generate cakey.pem  careq.pem , the key is private key of ca and req is public key and req for ca
openssl   req -new -keyout ./CA/cakey.pem -out ./CA/careq.pem -subj "/C=IR/ST=IR/L=Tehran/O=Behsa/OU=Ims/CN=behsacorp.com"
#openssl rsa  -in CA/cakey.pem -text
#openssl req  -in CA/careq.pem -text

#generate caroot.cer ; it generate a certificate using prviate key for ca and there is no signing from another ca
openssl   x509 -signkey ./CA/cakey.pem -req -days 3650 -in ./CA/careq.pem -out ./CA/caroot.cer -extensions v3_ca
#openssl x509 -in CA/caroot.cer -text

#import caroot.cer to keystore
keytool    -import -trustcacerts -alias ca -file ./CA/caroot.cer -keystore ./keys/keystore.jks -keypass qaz@1234 -storepass qaz@1234

#generate keystore ; recommended to use pkcs12
keytool    -genkeypair -alias ses -keyalg RSA -keystore ./keys/keystore.jks -keysize 2048 -keypass qaz@1234 -storepass qaz@1234 -dname "CN=sieebeltest.behsacorp.com,OU=Ims,O=Behsa,L=Tehran,ST=IR,C=IR" 
#the command below retrieve the generated certificate or private key. it first convert the keystore to pksc12 and then you can use openssl to retrieve the cert/key 
#keytool -importkeystore     -srckeystore keys/keystore.jks     -destkeystore keystore.p12     -deststoretype PKCS12     -srcalias ses    -deststorepass ahoora -destkeypass ahoora
#openssl pkcs12 -in keystore.p12  -nokeys -out cert.pem
#openssl x509  -in cert.pem -text
##openssl pkcs12 -in keystore.p12   -out cert.pem -nodes  -nocerts
##openssl rsa  -in cert.pem -text

#generate ses.csr ; it retrieves the just imported cer in a format of csr; doing opposite of signkey from careq.pem->caroot.cer
keytool    -certreq -alias ses -keystore ./keys/keystore.jks -file ./keys/ses.csr -keypass qaz@1234 -storepass qaz@1234
echo  20210815 > ./20210815
#generate ses.cer; this sign the csr with ca key 
openssl   x509 -CA ./CA/caroot.cer -CAkey ./CA/cakey.pem -CAserial 20210815 -req -in ./keys/ses.csr -out ./keys/ses.cer -days 365
#import ses.cer to keystore
keytool    -import -keystore ./keys/keystore.jks -file ./keys/ses.cer -alias ses -keypass qaz@1234 -storepass qaz@1234  
#Now test the .jks file :
keytool -list -keystore ./keys/keystore.jks -storepass qaz@1234


#/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt
#/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem
#/etc/pki/tls/cert.pem
#/etc/pki/pkitls/certs/ca-bundle.crt

echo "Iahoora@1234" |kinit cadmin
vip=siebelm.idm.mci.ir
ipa host-add ${vip} --ip-address=172.20.29.148
ipa service-add HTTP/${vip}
ipa service-add-host --hosts $(hostname) HTTP/${vip}
ipa-getcert request -D ${vip}  -f /etc/pki/tls/certs/${vip}.pem -k /etc/pki/tls/certs/${vip}.key -K HTTP/${vip} -N "CN=${vip}"
ipa-getcert list

#mkdir {CA,keys}
#keytool    -import -trustcacerts -alias ca -file /etc/pki/tls/cert.pem-keystore ./keys/keystore.jks -keypass qaz@1234 -storepass qaz@1234
#keytool    -import -keystore ./keys/keystore.jks -file /etc/pki/tls/certs/${vip}.pem  -alias ses -keypass qaz@1234 -storepass qaz@1234  
#keytool    -import -keystore ./keys/keystore.jks -file /etc/pki/tls/certs/${vip}.key  -alias seskey -keypass qaz@1234 -storepass qaz@1234  

openssl pkcs12 -export -in /etc/pki/tls/certs/${vip}.pem -inkey /etc/pki/tls/certs/${vip}.key -out /etc/pki/product/${vip}.pfx -passout pass:ahoora
keytool -importkeystore -deststorepass qaz@1234 -destkeystore /etc/pki/product/keystore.jks -srckeystore /etc/pki/product/${vip}.pfx -srcstoretype PKCS12 -srcstorepass ahoora




#############################################################################
#extract certificate from a pfx file
mkdir {CA,keys}
openssl pkcs12 -in 1400.pfx  -nodes -password pass:%M30%i20@N0AuthF@1400 -nokeys -info -nodes > mycert.crt
openssl pkcs12 -in 1400.pfx  -nodes -password pass:%M30%i20@N0AuthF@1400 -nodes -nocerts > mycert.key
keytool    -genkeypair -alias ses -keyalg RSA -keystore ./keys/keystore.jks -keysize 2048 -keypass qaz@1234 -storepass qaz@1234 -dname "CN=siebelvip.mci.ir,OU=Ims,O=Behsa,L=Tehran,ST=IR,C=IR" 
keytool    -import -trustcacerts -alias ca -file mycert.crt -keystore ./keys/keystore.jks -keypass qaz@1234 -storepass qaz@1234 -noprompt

keytool    -importcert -trustcacerts -alias ca -file mycert.crt -keystore ./keys/keystore.jks -keypass qaz@1234 -storepass qaz@1234 -noprompt



#################################################################################
#7-	Download the file as “behsacorp-com.pem” and upload it on /u01/new_ssl 
#8-	Same about “PEM (chain)” , save as behsacorp-com-chain.pem  and upload it on /u01/new_ssl 
#9-	Run below commands to make keystore and truststore in the same file “keystore.jks” by password “qaz@1234”
 openssl pkcs12 -export -in CaRoot.pem -inkey private.key -name siebeltest.behsacorp.com -out PKCS-12.p12
 keytool  -importkeystore -deststorepass qaz@1234 -destkeystore keystore.jks -srckeystore PKCS-12.p12 -srcstoretype PKCS12
 keytool  -import -trustcacerts -alias ca -file behsacorp-com.pem  -keystore keystore.jks -keypass qaz@1234 -storepass qaz@1234
 cp ./keystore.jks   ~
 
 #################################################################################
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

	
