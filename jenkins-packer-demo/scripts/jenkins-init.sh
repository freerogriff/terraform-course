#!/bin/bash

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
#apt-get update
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
yum -y install jenkins --nogpgcheck
systemctl start jenkins
systemctl enable jenkins


# install dependencies
#apt-get install -y python3 openjdk-11-jdk awscli
# install jenkins
#apt-get install -y jenkins=${JENKINS_VERSION} unzip
yum -y install python3 python3-pip java-11-openjdk-devel wget firewalld vim zip unzip ansible git bsdtar
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
aws/install
rm awscliv2.zip
aws --version
# install terraform
#wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
#&& unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
#&& rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
curl -L https://releases.hashicorp.com/terraform/1.1.7/terraform_1.1.7_linux_amd64.zip | sudo bsdtar -vxf - -C /usr/local/bin/
chmod a+x /usr/local/bin/terraform
# install packer
cd /usr/local/bin
#wget -q https://releases.hashicorp.com/packer/0.10.2/packer_0.10.2_linux_amd64.zip
#unzip packer_0.10.2_linux_amd64.zip
# clean up
#apt-get clean
curl -L https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_linux_amd64.zip | sudo bsdtar -vxf - -C /usr/local/bin/
chmod a+x /usr/local/bin/packer

rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
rm packer_0.10.2_linux_amd64.zip
