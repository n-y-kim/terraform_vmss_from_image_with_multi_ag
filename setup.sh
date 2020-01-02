##!/bin/bash

# create a folder for custom script and checkout code
cd ~
mkdir scripts
cd scripts

#install python  Dependencies
apt update
apt -y dist-upgrade
apt update
apt -y install python3-pip
pip3 install psutil bottle configparser Flask flask-api msrestazure azure-mgmt-resource azure-mgmt-compute azure-mgmt-network

#checkout code
git clone https://github.com/bedro96/terraform_vmss_from_image_with_ag.git

#Start health probe job
cd terraform_vmss_from_image_with_ag
chmod +x *.py
# nohup ./health_probe_handler.py & echo $! > health-probe-pid.file &
nohup ./healthprobe_flask.py & echo $! > health-probe-pid.file &

# Schedule cron jobs
crontab crons.sh

#################### datadisk_setup.sh ##################
# fdisk /dev/sdc
sudo sh -c 'echo "n\np\n\n\n\nw\n" | fdisk /dev/sdc'
# mkfs
sudo mkfs -t ext4 /dev/sdc1
# create a mount point
sudo mkdir -p /logs
sudo chmod 777 /logs
# mount
sudo mount /dev/sdc1 /logs
# Get UUID for /dev/sdc and place in fstab
# sudo -i blkid
# /dev/sdc1: UUID="33333333-3b3b-3c3c-3d3d-3e3e3e3e3e3e" TYPE="ext4"
sdc_uuid=$(sudo -i blkid | grep ^/dev/sdc1 | awk -F '"' '{print $2}')
# sdc_uuid=`sudo -i blkid | grep ^/dev/sdc1 | awk -F '"' '{print $2}'`
# UUID=33333333-3b3b-3c3c-3d3d-3e3e3e3e3e3e   /logs   ext4   defaults   1   2
inputstring="UUID=$sdc_uuid /logs ext4 defaults 1 2"
echo $inputstring | sudo tee -a /etc/fstab
sudo umount /logs
sudo mount /logs