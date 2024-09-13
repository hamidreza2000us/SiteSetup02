

cat >>  /root/.bashrc << EOF
export http_proxy=http://artifactory.idm.mci.ir:80
export https_proxy=http://artifactory.idm.mci.ir:80
export NO_PROXY=localhost,127.0.0.1
EOF


   1  curl yahoo.com
    2   podman run -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
    3  podman ps
    4  firewall-cmd --list-all
    5  firewall-cmd --add-port=7990/tcp --add-port=7999/tcp --permanent
    6  firewall-cmd --reload
    7  podman ps -a
    8  firewall-cmd --list-all
    9  podman ps
   10  systemctl stop firewalld
   11  podman restart b1e5842ee3fa
   12  setenforce 0
   13  top
   14  podman ps
   15  --privileged=true
   16  podman stop b1e5842ee3fa
   17  podman rm  b1e5842ee3fa
   18   podman run --privileged=true   -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   19  ip r sh
   20  nmcil con sh
   21  nmcli con sh
   22  nmcli con sh System \ens160
   23  nmcli con sh System\ ens160
   24  podman ps
   25  podman logs dfedcf7475f8
   26  podman logs -f  dfedcf7475f8
   27  df -h
   28  podman ps
   29  podman restart dfedcf7475f8
   30  podman logs -f  dfedcf7475f8
   31  podman ps
   32  podman restart dfedcf7475f8
   33  mkdir pgdata
   34  podman run --privileged=true --restart=always --name postgres -d  -p 5432:5432 -v /root/pgdata:/var/lib/postgresql/data:rw -e POSTGRES_PASSWORD=password -e POSTGRES_USER=artifactory -e POSTGRES_DB=artifactory docker.io/library/postgres:latest
   35  curl yahoo.com
   36  podman pull docker.io/library/postgres
   37  podman login docker.io
   38  podman pull docker.io/library/postgres
   39  podman pull docker.io/library/postgres:latest
   40  podman run --privileged=true --restart=always --name postgres -d  -p 5432:5432 -v /root/pgdata:/var/lib/postgresql/data:rw -e POSTGRES_PASSWORD=password -e POSTGRES_USER=artifactory -e POSTGRES_DB=artifactory docker.io/library/postgres:latest
   41  podman ps
   42  podman rm -f dfedcf7475f8
   43  podman ps -a
   44  history
   45  export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
   46  systemctl disable --now firewalld
   47  podman run --privileged=true --restart=always   --name artifactory-pro   -d -v /var/opt/jfrog/artifactory:/var/opt/jfrog/artifactory:rw -p 8081:8081 -p 8082:8082 -e DB_TYPE=postgresql -e DB_HOST=${IP} -e DB_PORT=5432 -e DB_USER=artifactory -e DB_PASSWORD=password -e JF_SHARED_DATABASE_DRIVER=org.postgresql.Driver -e DB_URL=jdbc:postgresql://${IP}:5432/artifactory -e JF_SHARED_DATABASE_USERNAME=artifactory docker.bintray.io/jfrog/artifactory-pro:latest \
   48  podman run --privileged=true   -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket \
   49  podman run --privileged=true -e JDBC_DRIVER=postgresql -e JDBC_URL=${IP} -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   50  podman logs 267890893c897018c6dec9c9dec2eab4c3da07f21b551ea1801cdda033b9ca27
   51  podman run --privileged=true -e JDBC_DRIVER=org.postgresql.Driver -e JDBC_URL=${IP} -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   52  history
   53  podman run --privileged=true -e JDBC_DRIVER=org.postgresql.Driver -e JDBC_URL=jdbc:postgresql://${IP}:5432/artifactory -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   54  podman ps
   55  podman rm -f 267890893c89
   56  podman run --privileged=true -e JDBC_DRIVER=org.postgresql.Driver -e JDBC_URL=jdbc:postgresql://${IP}:5432/artifactory -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   57  podman logs -f f56bdd3a1d57cfb9bf2ff109aa278465b93c3f4bd87cd0898f4b7953ccf86e5b
   58  podman ps
   59  podman rm -f f56bdd3a1d57
   60  podman run --privileged=true -e JDBC_DRIVER=org.postgresql.Driver -e JDBC_URL=jdbc:postgresql://${IP}:5432/artifactory -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v bitbucketVolume:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   61  podman rm -f d14ce61dd1ac3aab75902b3ffb7a83f5ea1f79b8269ab34548a0503ecd54bea8
   62  mkdir /opt/bit
   63  podman run --privileged=true -e JDBC_DRIVER=org.postgresql.Driver -e JDBC_URL=jdbc:postgresql://${IP}:5432/artifactory -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v /opt/bit:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   64  REPO=satellite.idm.mci.ir
   65  yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel
   66  curl http://${REPO}/pub/RHEL/Files/artifactory-injector-1.1.jar -o artifactory-injector-1.1.jar
   67  java -jar artifactory-injector-1.1.jar
   68  wget https://satellite.idm.mci.ir/pub/RHEL/Files/Atlassian/atlassian-agent-v1.2.3.tar.gz
   69  tar -xvf atlassian-agent-v1.2.3.tar.gz
   70  cd atlassian-agent-v1.2.3/
   71  ls
   72  vi README.pdf
   73  java -jar atlassian-agent.jar -p bitbucket -m hamid@yahoo.com -n bitbucket -o http://bitbucket.idm.mci.ir:7990 -s BRN5-J85E-JL4B-RKIA
   74  ls
   75  pwd
   76  java -jar atlassian-agent.jar -p bit -m hamid2@yahoo.com -n bitbucket -o http://bitbucket.idm.mci.ir:7990 -s BRN5-J85E-JL4B-RKIA
   77  java -jar atlassian-agent.jar -p bit -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s BRN5-J85E-JL4B-RKIA
   78  ls
   79  du -hs atlassian-agent.jar
   80  podman ps
   81  podman rm -f a9c8eaf21ead
   82  podman run --privileged=true -e JDBC_DRIVER=org.postgresql.Driver -e JDBC_URL=jdbc:postgresql://${IP}:5432/artifactory -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v /opt/bit:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket
   83  podman ps
   84  java -jar atlassian-agent.jar -p bit -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
   85  podman ps
   86  podman exec -it 2d9177618bf0 /bin/bash
   87  ls
   88  podman ps
   89  ls
   90* podman cp atlassian-agent.jar
   91  podman exec -it 2d9177618bf0 /bin/bash
   92  podman cp  2d9177618bf0:/opt/atlassian/bitbucket/bin/_start-webapp.sh .
   93  ls
   94  vi _start-webapp.sh
   95  -javaagent:  \
   96  history
   97  -javaagent:/opt/atlassian-agent.jar \
   98  vi _start-webapp.sh
   99  podman cp _start-webapp.sh 2d9177618bf0:/opt/atlassian/bitbucket/bin/_start-webapp.sh
  100  podman ps
  101  podman restart 2d9177618bf0
  102  java -jar atlassian-agent.jar -p bit -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
  103  podman ps
  104  podman logs 2d9177618bf0
  105  df -h
  106  podman ps
  107  podman restart 2d9177618bf0
  108  podman exec -it 2d9177618bf0 /bin/bash
  109  history
  110  podman exec -it 2d9177618bf0 /bin/bash
  111  podman restart 2d9177618bf0
  112  cat /etc/passwd
  113  podman restart 2d9177618bf0
  114  podman exec -it 2d9177618bf0 /bin/bash
  115  ls
  116  vi _start-webapp.sh
  117  JAVA_OPTS="-javaagent:/opt/atlassian-agent.jar  \
  118  podman cp _start-webapp.sh 2d9177618bf0:/opt/atlassian/bitbucket/bin/_start-webapp.sh
  119  podman restart 2d9177618bf0
  120  cp ~/.bashrc  .
  121  vi .bashrc
  122  podman cp .bashrc  2d9177618bf0:/var/atlassian/application-data/bitbucket/
  123  podman restart 2d9177618bf0
  124  history
  125  java -jar atlassian-agent.jar -p bit -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
  126  podman cp .bashrc  2d9177618bf0:/root/
  127  podman exec -it 2d9177618bf0 /bin/bash
  128  podman cp .bashrc  2d9177618bf0:/etc/bashrc
  129  podman restart 2d9177618bf0
  130  podman exec -it 2d9177618bf0 /bin/bash
  131  podman ps
  132  podman exec -it 2d9177618bf0 /bin/bash
  133  podman exec -it 2d9177618bf0 /bin/sh
  134  vi .bashrc
  135  podman cp .bashrc  2d9177618bf0:/etc/bashrc
  136  podman restart 2d9177618bf0
  137  podman exec -it 2d9177618bf0 /bin/bash
  138  java -jar atlassian-agent.jar -p bit -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
  139  java -jar atlassian-agent.jar -p Bitbucket -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
  140  podman restart 2d9177618bf0
  141  podman exec -it 2d9177618bf0 /bin/bash
  142  ls
  143  vi _start-webapp.sh
  144  podman cp _start-webapp.sh 2d9177618bf0:/opt/atlassian/bitbucket/bin/_start-webapp.sh
  145  podman restart 2d9177618bf0
  146  podman exec -it 2d9177618bf0 /bin/bash
  147  podman ps
  148  podman logs 2d9177618bf0
  149  cd
  150  ls
  151  unzip atlassian-agent-v1.3.1.zip
  152  ls
  153  cd atlassian-agent-v1.3.1/
  154  ls
  155  podman ps
  156  podman cp atlassian-agent.jar 2d9177618bf0:/opt/
  157  podman restart atlassian-agent.jar
  158  podman restart 2d9177618bf0
  159*
  160  cd ..
  161  ls
  162  cd atlassian-agent-v1.2.3/
  163  ls
  164  vi _start-webapp.sh
  165  podman cp _start-webapp.sh 2d9177618bf0:/opt/atlassian/bitbucket/bin/_start-webapp.sh
  166  cd ../atlassian-agent-v1.3.1/
  167  podman cp atlassian-agent.jar 2d9177618bf0:/
  168  podman restart 2d9177618bf0
  169  vi _start-webapp.sh
  170  cd -
  171  vi _start-webapp.sh
  172  podman images
  173  podman search bitbucket
  174  podman images
  175  podman search atlassian/bitbucket
  176  curl docker.io/v2/atlassian/bitbucket/tags/list
  177  curl docker.io/v2/bitbucket/tags/list
  178  curl docker.io/v2/docker.io/atlassian/bitbucket/tags/list
  179  curl https://docker.io/v2/docker.io/atlassian/bitbucket/tags/list
  180  curl https://docker.io/v2/atlassian/bitbucket/tags/list
  181  podman exec -it 2d9177618bf0 /bin/bash
  182  podman restart 2d9177618bf0
  183  podman exec -it 2d9177618bf0 /bin/bash
  184   com.plugin.commitgraph.commitgraph \
  185  java -jar atlassian-agent.jar -p Bitbucket -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA \
  186   java -jar atlassian-agent.jar  -h
  187  ls
  188  vi _start-webapp.sh
  189  podman cp _start-webapp.sh 2d9177618bf0:/opt/atlassian/bitbucket/bin/_start-webapp.sh
  190  podman exec -it 2d9177618bf0 /bin/bash
  191  podman ps
  192  podman cp 2d9177618bf0:/etc/profile .
  193  vi profile
  194  podman cp profile 2d9177618bf0:/etc/profile
  195  podmran restart 2d9177618bf0
  196  podman restart 2d9177618bf0
  197  history | grep "java -jar atlassian-agent.jar"
  198  java -jar atlassian-agent.jar -p bitbucket -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
  199  podman exec -it 2d9177618bf0 /bin/bash
  200  vi profile
  201  podman cp profile 2d9177618bf0:/etc/profile
  202  podman restart 2d9177618bf0
  203  java -jar atlassian-agent.jar -p bitbucket -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA \
  204  cd -
  205  java -jar atlassian-agent.jar -p bitbucket -m hamid2@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
  206  podman cp atlassian-agent.jar 2d9177618bf0:/var/atlassian/application-data/bitbucket/bin/atlassian-agent.jar
  207  podman restart 2d9177618bf0
  208  java -jar atlassian-agent.jar -p bitbucket -m hamid@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
  209  history

  
firewall-cmd --add-port=7990/tcp --add-port=7999/tcp --permanent
firewall-cmd --reload
	
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
systemctl disable --now firewalld
  
podman rm -f postgres bitbucket
rm -rf   /root/pgdata 
rm -rf /opt/bit
  
mkdir /root/pgdata
podman run --privileged=true --restart=always --name postgres -d  -p 5432:5432 -v /root/pgdata:/var/lib/postgresql/data:rw -e POSTGRES_PASSWORD=password -e POSTGRES_USER=artifactory -e POSTGRES_DB=artifactory docker.io/library/postgres:latest
  
mkdir /opt/bit
podman run --privileged=true -e JDBC_DRIVER=org.postgresql.Driver -e JDBC_URL=jdbc:postgresql://${IP}:5432/artifactory -e JDBC_USER=artifactory -e JDBC_PASSWORD=password   -v /opt/bit:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 atlassian/bitbucket:6.5.1

############wait for app to fully start and then continue#############
cd /root/atlassian-agent-v1.3.1
podman cp atlassian-agent.jar bitbucket:/var/atlassian/application-data/bitbucket/bin/atlassian-agent.jar 
podman exec bitbucket chown bitbucket:bitbucket /var/atlassian/application-data/bitbucket/bin/atlassian-agent.jar

#podman cp bitbucket:/opt/atlassian/bitbucket/bin/_start-webapp.sh .
#podman cp _start-webapp.sh bitbucket:/opt/atlassian/bitbucket/bin/_start-webapp.sh
#podman exec bitbucket chown bitbucket:bitbucket /opt/atlassian/bitbucket/bin/_start-webapp.sh

 
echo 'export JAVA_OPTS=" -javaagent:/var/atlassian/application-data/bitbucket/bin/atlassian-agent.jar ${JAVA_OPTS}"' > profile 
podman cp profile bitbucket:/etc/profile 

podman restart bitbucket
podman logs -f bitbucket

java -jar atlassian-agent.jar -p bitbucket -m hamid@yahoo.com -n Bitbucket -o http://bitbucket.idm.mci.ir:7990 -s  BRN5-J85E-JL4B-RKIA
