#!/bin/bash

#"echo 'hello from $HOST' > ~/terraform_complete",
curl -L -o /opt/openjdk-11.0.2_linux-x64_bin.tar.gz -O https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
mkdir /usr/local/open-java-11
tar -zxf /opt/openjdk-11.0.2_linux-x64_bin.tar.gz -C /usr/local/open-java-11
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python2.7
ln -s /usr/bin/python2.7 /usr/local/bin/python

for f in /sys/kernel/mm/*transparent_hugepage/enabled; do
    if test -f $f; then echo never > $f; fi
done
for f in /sys/kernel/mm/*transparent_hugepage/defrag; do
    if test -f $f; then echo never > $f; fi
done

echo -e '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <license>
                <permit version="1" scheme="0">
                <type>Enterprise Edition</type>
                <issuer>
                <company>VoltDB</company>
                <email>support@voltdb.com</email>
                <url>http://voltdb.com/</url>
                </issuer>
                <issuedate>2019-01-09</issuedate>
                <licensee>VoltDB Field Engineering</licensee>
                <expiration>2020-01-09</expiration>
                <hostcount max="200"/>
                <features trial="false">
                <wanreplication>true</wanreplication>
                <dractiveactive>true</dractiveactive>
                </features>
                </permit>
                <signature>
                302C02147F6B637FC0267E4F46F4E4E704A41FB8FD44AD
                4802146DD24AB72C167F63E069894C460F9028AE3559FF
                </signature>
                </license>' > ~/license.xml
            
echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
              <deployment>
              <cluster sitesperhost=\"8\" kfactor=\"0\" />
              <commandlog synchronous=\"false\" enabled=\"true\" logsize=\"10000\"/>
              <snapshot enabled=\"false\"/>
              <httpd enabled=\"true\">
              <jsonapi enabled=\"true\" />
              </httpd>
              <systemsettings>
              <temptables maxsize=\"1024\"/>
              <query timeout=\"30000\"/>
              </systemsettings>
              </deployment>" > ~/deployment.xml

curl -L -o /opt/voltdb-ent-9.0.tar.gz -O https://downloads.voltdb.com/technologies/server/voltdb-ent-9.0.tar.gz
tar -xzvf /opt/voltdb-ent-9.0.tar.gz -C /opt/
mv /opt/voltdb-ent-9.0 /opt/voltdb
update-alternatives --install "/usr/bin/java" "java" "/usr/local/open-java-11/jdk-11.0.2/bin/java" 1500
update-alternatives --install "/usr/bin/javac" "javac" "//usr/local/open-java-11/jdk-11.0.2/bin/javac" 1500
update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/local/open-java-11/jdk-11.0.2/bin/javaws" 1500
update-alternatives --install "/usr/bin/jps" "jps" "/usr/local/open-java-11/jdk-11.0.2/bin/jps" 1500
echo -e 'export VOLT=/opt/voltdb' >> ~/.bashrc
echo -e 'export PATH=$PATH:$VOLT/bin' >> ~/.bashrc
echo -e 'export VOLTDB_HEAPMAX="2048"' >> ~/.bashrc
mv -f ~/license.xml /opt/voltdb/voltdb/
/opt/voltdb/bin/voltdb init -f -C ~/deployment.xml >> ~/voltdb_init.log
export VOLTDB_HEAPMAX="2048"
pip install -r /opt/voltdb/lib/python/voltsql/requirements.txt

#Install Docker & K8s
apt install -y docker.io
systemctl enable docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
apt install -y software-properties-common
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt install -y kubeadm
swapoff -a

# Add new users.
useradd -m -G root hadoop
echo 'hadoop' | passwd hadoop --stdin &>/dev/null
