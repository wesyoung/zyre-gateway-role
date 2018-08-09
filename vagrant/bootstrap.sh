#!/usr/bin/env bash
private_ip="172.30.0.145"
public_ip=`dig +short myip.opendns.com @resolver1.opendns.com`
pyzyre_version="master"
pyzyre_debug="True"
app_user="zyre"
app_group="zyre"
zyre_group="group1"
zyre_broker_node_name="zyre-broker"
zyre_broker_gossip_bind="tcp://${private_ip}:49154"
zyre_broker_endpoint="tcp://${private_ip}:49155"
zyre_broker_advertise_endpoint="tcp://${public_ip}:49155"

# to generate your keys- install pyzyre locally
# $ mkdir ~/.curve && chmod 770 ~/.curve
# $ zyre-certs
# use keys from ~/.curve/test.key_secret here
# or use these AT YOUR OWN RISK!!!
zyre_broker_publickey="jG#7UCG2e#paJKOrLUk5#SIn5e16c1k\&CE\*57Wp\!"
zyre_broker_secretkey="4)}j\$^-{\$JhngCSBUP1Po7CpbL8HYEtTlCcvbS4F"

export DEBIAN_FRONTEND=noninteractive

echo "${private_ip} zyre-broker" > /etc/hosts

hostname zyre-broker
useradd -s /bin/bash -m -d /home/${app_user} ${app_user}


apt-get update && apt-get install python-minimal aptitude -y
wget -qO - http://download.opensuse.org/repositories/network:/messaging:/zeromq:/git-draft/xUbuntu_16.04/Release.key | apt-key add -
add-apt-repository 'deb http://download.opensuse.org/repositories/network:/messaging:/zeromq:/git-draft/xUbuntu_16.04/ /'
apt-get update && apt-get install build-essential libtool pkg-config autotools-dev autoconf automake cmake uuid-dev libpcre3-dev valgrind libffi-dev autoconf libtool libczmq-dev libzyre-dev python-pip htop -y

pip install --upgrade pip
hash -d pip
hash -r pip
pip install cython
pip install 'pyzmq>=16.0.4,<17' --no-binary :all:
pip install pyzyre

wget https://github.com/wesyoung/pyzyre/archive/${pyzyre_version}.tar.gz -O /tmp/pyzyre.tar.gz

tar -zxvf /tmp/pyzyre.tar.gz -C /tmp/

pyzyre_release_dir=`echo "${pyzyre_version}" | sed 's/\//-/g'`

echo "pyzyre release dir is ${pyzyre_release_dir}"

cd /tmp/pyzyre-${pyzyre_version}
pip install -r dev_requirements.txt

#cd /tmp/pyzyre-${pyzyre_release_dir}
#PYZYRE_BUILD_MASTER=1 PYZYRE_ZYRE_BUILD_MASTER=1 python setup.py build_ext sdist

#cd /tmp/pyzyre-${pyzyre_release_dir}
#python setup.py test

#cd /tmp/pyzyre-${pyzyre_release_dir}
#python setup.py install

zyre-broker -h > /vagrant/test2.output

ufw_ports=( 22 49152 49153 49154 49155 49156 )
for i in "${ufw_ports[@]}"
do
    echo $i
    ufw allow $i
done
ufw enable

wget https://www.github.com/wesyoung/zyre-gateway-role/raw/${pyzyre_version}/roles/zyre/templates/broker.env.j2 -O /etc/broker.env
chmod 0600 /etc/broker.env
chown ${app_user}:${app_group} /etc/broker.env
chmod 664 /etc/broker.env
sed -i 's@{{ zyre_broker_node_name }}@'$zyre_broker_node_name'@g' /etc/broker.env
sed -i 's@{{ zyre_broker_endpoint }}@'$zyre_broker_endpoint'@g' /etc/broker.env
sed -i 's@{{ zyre_broker_gossip_bind }}@'$zyre_broker_gossip_bind'@g' /etc/broker.env
sed -i 's@{{ zyre_broker_advertise_endpoint }}@'$zyre_broker_advertise_endpoint'@g' /etc/broker.env
sed -i 's@{{ zyre_group }}@'$zyre_group'@g' /etc/broker.env
sed -i 's@{{ zyre_broker_publickey }}@'$zyre_broker_publickey'@g' /etc/broker.env
sed -i 's@{{ zyre_broker_secretkey }}@'$zyre_broker_secretkey'@g' /etc/broker.env

wget https://www.github.com/wesyoung/zyre-gateway-role/raw/${pyzyre_version}/roles/zyre/templates/zyre-broker.service.j2 -O /etc/systemd/system/zyre-broker.service
chown root:root /etc/systemd/system/zyre-broker.service
chmod 0644 /etc/systemd/system/zyre-broker.service
sed -i 's@{{ app_user }}@'${app_user}'@g' /etc/systemd/system/zyre-broker.service
sed -i 's@{{ zyre_group }}@'${zyre_group}'@g' /etc/systemd/system/zyre-broker.service
sed -i 's@{{ zyre_broker_advertise_endpoint }}@'${zyre_broker_advertise_endpoint}'@g' /etc/systemd/system/zyre-broker.service
sed -i 's@{{ zyre_broker_endpoint }}@'${zyre_broker_endpoint}'@g' /etc/systemd/system/zyre-broker.service
sed -i 's@{{ zyre_broker_gossip_bind }}@'${zyre_broker_gossip_bind}'@g' /etc/systemd/system/zyre-broker.service
systemctl daemon-reload
systemctl enable zyre-broker

mkdir -p /home/${app_user}/.curve
chown ${app_user}:${app_group} /home/${app_user}/.curve
chmod 0700 /home/${app_user}/.curve
wget https://www.github.com/wesyoung/zyre-gateway-role/raw/${pyzyre_version}/roles/zyre/templates/broker.key_secret.j2 -O /home/${app_user}/.curve/certs
chown ${app_user}:${app_group} /home/${app_user}/.curve/certs
chmod 0600 /home/${app_user}/.curve/certs
sed -i 's@{{ zyre_broker_publickey }}@'$zyre_broker_publickey'@g' /home/${app_user}/.curve/certs
sed -i 's@{{ zyre_broker_secretkey }}@'$zyre_broker_secretkey'@g' /home/${app_user}/.curve/certs

service zyre-broker start
service zyre-broker status
