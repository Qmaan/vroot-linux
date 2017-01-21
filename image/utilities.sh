#!/bin/bash
set -e
source /build/buildconfig
set -x

#apt-get update
#apt-get dist-upgrade -y --force-yes --no-install-recommends

## Often used tools.
$minimal_apt_get_install --force-yes curl less nano vim psmisc tcpdump iputils-ping \
iputils-arping iputils-tracepath net-tools file telnet isc-dhcp-client nmap \
dnsutils netcat man dsniff traceroute ettercap-text-only tcpreplay hping3 p0f \
lsof strace elinks iperf iftop scapy bsd-mailx ndisc6 radvd iptables tayga \
libmysqlclient-dev libsmi2ldbl snmp-mibs-downloader python-dev libevent-dev \
libxslt1-dev libxml2-dev python-pip python-mysqldb pkg-config libvirt-dev build-essential \
inotify-tools libssl-dev postfix mailutils libsasl2-2 ca-certificates libsasl2-modules

##### CONPOT INSTALLATION #####
pip install -U pip setuptools
pip install -I bacpypes==0.14.0

pip install conpot


##### POSTFIX INSTALATION #####

sed -i 's/relayhost =/relayhost = [smtp.gmail.com]:587/' /etc/postfix/main.cf

echo 'smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/postfix/cacert.pem
smtp_use_tls = yes' >> /etc/postfix/main.cf

#insert mail and password into sasl_passwd
echo "[smtp.gmail.com]:587    USERMAIL:PASSWORDMAIL" >> /etc/postfix/sasl_passwd

chmod 400 /etc/postfix/sasl_passwd

postmap /etc/postfix/sasl_passwd

cat /etc/ssl/certs/thawte_Primary_Root_CA.pem | tee -a /etc/postfix/cacert.pem

##### OSSEC INSTALATION #####
wget -U ossec http://www.ossec.net/files/ossec-hids-2.8.1.tar.gz

tar -zxf ossec-hids-2.8.1.tar.gz

#### OSSEC CONFIGURATION ####
#---------------------------#
echo 'USER_LANGUAGE="en"
USER_NO_STOP="y"
USER_INSTALL_TYPE="local"
USER_DIR="/var/ossec"
USER_DELETE_DIR="y"
USER_ENABLE_ACTIVE_RESPONSE="y"
USER_ENABLE_SYSCHECK="y"
USER_ENABLE_ROOTCHECK="n"' >/ossec-hids-2.8.1/etc/preloaded-vars.conf

echo 'USER_ENABLE_EMAIL="y"' >>/ossec-hids-2.8.1/etc/preloaded-vars.conf
echo 'USER_EMAIL_SMTP="localhost"
USER_EMAIL_ADDRESS="USERMAIL"' >>/ossec-hids-2.8.1/etc/preloaded-vars.conf

echo 'USER_ENABLE_SYSLOG="y"
USER_ENABLE_FIREWALL_RESPONSE="n"
USER_WHITE_LIST="192.168.1.0/24"' >>/ossec-hids-2.8.1/etc/preloaded-vars.conf
#---------------------------#
sed -i 's/<frequency>79200<\/frequency>/<frequency>60<\/frequency>/' /ossec-hids-2.8.1/etc/templates/config/syscheck.template

bash ossec-hids-2.8.1/install.sh

echo 'USER_LANGUAGE="en"
USER_NO_STOP="y"
USER_UPDATE="y"
USER_UPDATE_RULES="y"' >/ossec-hids-2.8.1/etc/preloaded-vars.conf

bash ossec-hids-2.8.1/install.sh






