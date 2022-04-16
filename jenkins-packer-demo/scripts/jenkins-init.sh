#!/bin/bash -xv

# volume setup
vgchange -ay

DEVICE_FS=`blkid -o value -s TYPE ${DEVICE}`
if [ "`echo -n $DEVICE_FS`" == "" ] ; then 
  # wait for the device to be attached
  DEVICENAME=`echo "${DEVICE}" | awk -F '/' '{print $3}'`
  DEVICEEXISTS=''
  while [[ -z $DEVICEEXISTS ]]; do
    echo "checking $DEVICENAME"
    DEVICEEXISTS=`lsblk |grep "$DEVICENAME" |wc -l`
    if [[ $DEVICEEXISTS != "1" ]]; then
      sleep 15
    fi
  done
  pvcreate ${DEVICE}
  vgcreate data ${DEVICE}
  lvcreate --name volume1 -l 100%FREE data
  mkfs.ext4 /dev/data/volume1
fi
mkdir -p /var/lib/jenkins
echo '/dev/data/volume1 /var/lib/jenkins ext4 defaults 0 0' >> /etc/fstab
mount /var/lib/jenkins

# jenkins repository
#wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
#echo "deb http://pkg.jenkins.io/debian-stable binary/" >> /etc/apt/sources.list
echo "updating"
echo "updating"
#apt-get update
yum update -y

# install dependencies
#apt-get install -y python3 openjdk-11-jdk awscli
#yum -y install python3 awscli java-11-openjdk-devel wget firewalld unzip
echo "installing python3 pip3 java11 wget firewalld unzip ansible git"
echo "installing python3 pip3 java11 wget firewalld unzip ansible git"
#sudo yum -y clean expire-cache && sudo yum -y update
yum -y install python3 python3-pip java-11-openjdk-devel wget firewalld vim zip unzip ansible git bsdtar
#echo "installing groovy"
#echo "installing groovy"
#sudo -H -u ec2-user bash -c 'curl -s get.sdkman.io | bash' && \
#sudo -H -u ec2-user bash -c 'source "/home/ec2-user/.sdkman/bin/sdkman-init.sh"' && \
#sudo -H -u ec2-user bash -c 'sdk install groovy'

#dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#dnf upgrade -y 
#subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"
#yum update -y
#yum install -y snapd
#systemctl enable --now snapd.socket
#ln -s /var/lib/snapd/snap /snap
#sleep 15
#snap install groovy --classic
#export PATH=/snap/bin:$PATH


echo "installing awscli"
echo "installing awscli"
#sudo -H -u ec2-user bash -c 'pip3 install awscli'
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
aws/install
rm awscliv2.zip
aws --version



# install jenkins
echo "installing jenkins"
echo "installing jenkins"
#apt-get install -y jenkins=${JENKINS_VERSION} unzip
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
yum -y install jenkins --nogpgcheck
systemctl start jenkins
systemctl enable jenkins
#echo "configuring firewalld"
#echo "configuring firewalld"
#systemctl unmask firewalld
#firewall-offline-cmd --add-port=jenkins/tcp --permanent
#systemctl start firewalld
#systemctl enable firewalld

echo "installing terraform"
echo "installing terraform"
curl -L https://releases.hashicorp.com/terraform/1.1.8/terraform_1.1.8_linux_amd64.zip | sudo bsdtar -vxf - -C /usr/local/bin/
chmod a+x /usr/local/bin/terraform

# install terraform
#wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
#&& unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
#&& /bin/rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# install packer
echo "installing packer"
echo "installing packer"
curl -L https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_linux_amd64.zip | sudo bsdtar -vxf - -C /usr/local/bin/
chmod a+x /usr/local/bin/packer
#cd /usr/local/bin
#wget -q https://releases.hashicorp.com/packer/0.10.2/packer_0.10.2_linux_amd64.zip
#wget -q https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_linux_amd64.zip
#unzip packer_1.8.0_linux_amd64.zip
#wget -q https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_linux_amd64.zip && unzip packer_1.8.0_linux_amd64.zip -d /usr/local/bin && /bin/rm -f packer_1.8.0_linux_amd64.zip
export JENKINS_HOME=/var/lib/jenkins
echo "disable jenkins setup wizard"
echo "disable jenkins setup wizard"
echo 'JAVA_ARGS="-Djenkins.install.runSetupWizard=false"' >> /etc/sysconfig/jenkins
systemctl restart jenkins
cd /home/ec2-user
mkdir -p jenkins_jobs/terraform-apply jenkins_jobs/packer-build
cd jenkins_jobs/packer-build && wget https://raw.githubusercontent.com/freerogriff/terraform-course/master/jenkins-packer-demo/jenkins_jobs/packer-build/config.xml
cd ../terraform-apply && wget https://raw.githubusercontent.com/freerogriff/terraform-course/master/jenkins-packer-demo/jenkins_jobs/terraform-apply/config.xml
cd /home/ec2-user
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
wget https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.3/jenkins-plugin-manager-2.12.3.jar

java -jar jenkins-cli.jar -auth admin:$pass -s http://localhost:8080 create-job packer-build < /home/ec2-user/jenkins_jobs/packer-build/config.xml
java -jar jenkins-cli.jar -auth admin:$pass -s http://localhost:8080 create-job terraform-apply < /home/ec2-user/jenkins_jobs/terraform-apply/config.xml

#last_tasks () {
# /usr/bin/firewall-cmd --add-port=8080/tcp --permanent
# /usr/bin/firewall-cmd --runtime-to-permanent
# /usr/bin/firewall-cmd --reload
# systemctl restart jenkins
# }

#last_tasks


cd /var/lib/jenkins
mkdir init.groovy.d
chown -R jenkins:jenkins init.groovy.d 
cat << EOF > /var/lib/jenkins/init.groovy.d/basic-security.groovy
#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def instance = Jenkins.getInstance()

instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
EOF

cat << EOF > /etc/systemd/system/very-last.service
[Unit]
Description=Very last service
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/very-last

[Install]
WantedBy=multi-user.target
EOF

#systemctl enable very-last
#WantedBy=default.target
cat << EOF > /usr/local/sbin/very-last
#!/bin/bash

#ansible-playbook /home/ec2-user/missing.yml -i localhost,
pass=`cat /var/lib/jenkins/secrets/initialAdminPassword`

pass=`cat /var/lib/jenkins/secrets/initialAdminPassword` && echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("terraform", "Opala11")' | java -jar /home/ec2-user/jenkins-cli.jar -auth admin:\$pass -s http://localhost:8080/ groovy =

java -jar /home/ec2-user/jenkins-plugin-manager-2.12.3.jar --war /usr/share/java/jenkins.war --plugin-download-directory /var/lib/jenkins/plugins --plugins git javadoc junit aws-credentials --verbose

java -jar /home/ec2-user/jenkins-cli.jar -auth admin:\$pass -s http://localhost:8080 create-job packer-build < /home/ec2-user/jenkins_jobs/packer-build/config.xml
java -jar /home/ec2-user/jenkins-cli.jar -auth admin:\$pass -s http://localhost:8080 create-job terraform-apply < /home/ec2-user/jenkins_jobs/terraform-apply/config.xml

java -jar /home/ec2-user/jenkins-cli.jar -auth admin:\$pass -s http://localhost:8080/ restart
EOF

systemctl daemon-reload
systemctl enable very-last

chmod 700 /usr/local/sbin/very-last

chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/basic-security.groovy
systemctl restart jenkins
/bin/rm -f /var/lib/jenkins/init.groovy.d/basic-security.groovy
sed -i "s/webcache/\\#webcache/g" /etc/services
sed -i '555 i jenkins        8080/tcp        jenkins        # Jenkins service' /etc/services

echo "configuring firewalld"
echo "configuring firewalld"
systemctl unmask firewalld
firewall-offline-cmd --add-port=jenkins/tcp
systemctl start firewalld
systemctl enable firewalld



cat << EOF > /home/ec2-user/missing.yml
---
 - name: FirewallD
   hosts: localhost
   connection: local
   tasks:
    - name: FirewallD rules
      firewalld:
        permanent: yes
        immediate: yes
        service: "{{ item }}"
        state: enabled
      with_items:
       - jenkins

    - name: Run CRON job ensure port 8080 every 5 minutes
      become: yes
      become_method: sudo
      cron:
        name: "jenkins_port_8080"
        user: "root"
        weekday: "*"
        minute: "05"
        hour: "*"
        job: "ansible-playbook /home/ec2-user/missing.yml -i localhost,
        state: present
EOF

#ansible-playbook /home/ec2-user/missing.yml -i localhost,
#pass=`cat /var/lib/jenkins/secrets/initialAdminPassword` 

#pass=`cat /var/lib/jenkins/secrets/initialAdminPassword` && echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("terraform", "Opala11")' | sudo java -jar jenkins-cli.jar -auth admin:$pass -s http://localhost:8080/ groovy =

#java -jar jenkins-plugin-manager-2.12.3.jar --war /usr/share/java/jenkins.war --plugin-download-directory /var/lib/jenkins/plugins --plugins git javadoc junit aws-credentials --verbose

#java -jar jenkins-cli.jar -auth admin:$pass -s http://localhost:8080/ restart





# clean up
#apt-get clean
echo "cleaning up zip files"
echo "cleaning up zip files"
/bin/rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
/bin/rm -f packer_1.8.0_linux_amd64.zip
restorecon -Fvvv /usr/local/sbin/very-last
shutdown -r now

