#!/bin/bash -x

# Zimbra mail server installation in Ubuntu 14.04 and 16.04
# Author: Sounay (hosting4lao.com)

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

## Preparing all the variables like IP, Hostname, etc, all of them from the server
RANDOMHAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMSPAM=$(date +%s|sha256sum|base64|head -c 10)
RANDOMVIRUS=$(date +%s|sha256sum|base64|head -c 10)
HOSTNAME=$(hostname -s)

##Install a DNS Server
sudo apt-get update && sudo apt-get install -y bind9 bind9utils bind9-doc
echo "Installing Bind DNS Server"
sed "s/-u/-4 -u/g" /etc/default/bind9 > /etc/default/bind9.new
mv /etc/default/bind9.new /etc/default/bind9
rm /etc/bind/named.conf.options
cat <<EOF >>/etc/bind/named.conf.options
options {
directory "/var/cache/bind";
listen-on { $2; }; # ns1 private IP address - listen on private network only
allow-transfer { none; }; # disable zone transfers by default
forwarders {
8.8.8.8;
8.8.4.4;
};
auth-nxdomain no; # conform to RFC1035
#listen-on-v6 { any; };
};
EOF
cat <<EOF >>/etc/bind/named.conf.local
zone "$1" {
        type master;
        file "/etc/bind/db.$1";
};
EOF
touch /etc/bind/db.$1
cat <<EOF >/etc/bind/db.$1
\$TTL  604800
@      IN      SOA    $1. root.localhost. (
                                2        ; Serial
                        604800        ; Refresh
                        86400        ; Retry
                        2419200        ; Expire
                        604800 )      ; Negative Cache TTL
    ;
    @     IN      NS      $1.
    @     IN      A      $2
    @     IN      MX     10     $1.
    $1     IN      A      $2
    ns1     IN      A      $2
    mail     IN      A      $2
    pop3     IN      A      $2
    imap     IN      A      $2
    imap4     IN      A      $2
    smtp     IN      A      $2
EOF
sudo service bind9 restart

##Preparing the config files to inject
echo "Creating the Scripts files"
mkdir /tmp/zcs && cd /tmp/zcs
touch /tmp/zcs/installZimbraScript
cat <<EOF >/tmp/zcs/installZimbraScript
AVDOMAIN="$1"
AVUSER="admin@$1"
CREATEADMIN="admin@$1"
CREATEADMINPASS="$3"
CREATEDOMAIN="$1"
DOCREATEADMIN="yes"
DOCREATEDOMAIN="yes"
DOTRAINSA="yes"
EXPANDMENU="no"
HOSTNAME="$1"
HTTPPORT="8080"
HTTPPROXY="TRUE"
HTTPPROXYPORT="80"
HTTPSPORT="8443"
HTTPSPROXYPORT="443"
IMAPPORT="7143"
IMAPPROXYPORT="143"
IMAPSSLPORT="7993"
IMAPSSLPROXYPORT="993"
INSTALL_WEBAPPS="service zimlet zimbra zimbraAdmin"
JAVAHOME="/opt/zimbra/common/lib/jvm/java"
LDAPAMAVISPASS="$3"
LDAPPOSTPASS="$3"
LDAPROOTPASS="$3"
LDAPADMINPASS="$3"
LDAPREPPASS="$3"
LDAPBESSEARCHSET="set"
LDAPDEFAULTSLOADED="1"
LDAPHOST="$1"
LDAPPORT="389"
LDAPREPLICATIONTYPE="master"
LDAPSERVERID="2"
MAILBOXDMEMORY="512"
MAILPROXY="TRUE"
MODE="https"
MYSQLMEMORYPERCENT="30"
POPPORT="7110"
POPPROXYPORT="110"
POPSSLPORT="7995"
POPSSLPROXYPORT="995"
PROXYMODE="https"
REMOVE="no"
RUNARCHIVING="no"
RUNAV="yes"
RUNCBPOLICYD="no"
RUNDKIM="yes"
RUNSA="yes"
RUNVMHA="no"
SERVICEWEBAPP="yes"
SMTPDEST="admin@$1"
SMTPHOST="$1"
SMTPNOTIFY="yes"
SMTPSOURCE="admin@$1"
SNMPNOTIFY="yes"
SNMPTRAPHOST="$1"
SPELLURL="http://$1:7780/aspell.php"
STARTSERVERS="yes"
SYSTEMMEMORY="3.8"
TRAINSAHAM="ham.$RANDOMHAM@$1"
TRAINSASPAM="spam.$RANDOMSPAM@$1"
UIWEBAPPS="yes"
UPGRADE="yes"
USEKBSHORTCUTS="TRUE"
USESPELL="yes"
VERSIONUPDATECHECKS="TRUE"
VIRUSQUARANTINE="virus-quarantine.$RANDOMVIRUS@$1"
ZIMBRA_REQ_SECURITY="yes"
ldap_bes_searcher_password="$3"
ldap_dit_base_dn_config="cn=zimbra"
ldap_nginx_password="$3"
ldap_url="ldap://$1:389"
mailboxd_directory="/opt/zimbra/mailboxd"
mailboxd_keystore="/opt/zimbra/mailboxd/etc/keystore"
mailboxd_keystore_password="$3"
mailboxd_server="jetty"
mailboxd_truststore="/opt/zimbra/common/lib/jvm/java/jre/lib/security/cacerts"
mailboxd_truststore_password="changeit"
postfix_mail_owner="postfix"
postfix_setgid_group="postdrop"
ssl_default_digest="sha256"
zimbraDNSMasterIP=""
zimbraDNSTCPUpstream="no"
zimbraDNSUseTCP="yes"
zimbraDNSUseUDP="yes"
zimbraDefaultDomainName="$1"
zimbraFeatureBriefcasesEnabled="Enabled"
zimbraFeatureTasksEnabled="Enabled"
zimbraIPMode="ipv4"
zimbraMailProxy="FALSE"
zimbraMtaMyNetworks="127.0.0.0/8 $2/32 [::1]/128 [fe80::]/64"
zimbraPrefTimeZoneId="Asia/Vientiane"
zimbraReverseProxyLookupTarget="TRUE"
zimbraVersionCheckInterval="1d"
zimbraVersionCheckNotificationEmail="admin@$1"
zimbraVersionCheckNotificationEmailFrom="admin@$1"
zimbraVersionCheckSendNotifications="TRUE"
zimbraWebProxy="FALSE"
zimbra_ldap_userdn="uid=zimbra,cn=admins,cn=zimbra"
zimbra_require_interprocess_security="1"
zimbra_server_hostname="$1"
INSTALL_PACKAGES="zimbra-core zimbra-ldap zimbra-logger zimbra-mta zimbra-snmp zimbra-store zimbra-apache zimbra-spell zimbra-memcached zimbra-proxy"
EOF

touch /tmp/zcs/installZimbra-keystrokes
cat <<EOF >/tmp/zcs/installZimbra-keystrokes
y
y
y
y
y
n
y
y
y
y
y
y
y
n
y
y
EOF

## Install Zimbra Mail Server
if [[ `lsb_release -rs` == "16.04" ]]; then
	echo "Downloading Zimbra Collaboration 8.8.10 for Ubuntu 16.04"
	wget https://files.zimbra.com/downloads/8.8.12_GA/zcs-8.8.12_GA_3794.UBUNTU16_64.20190329045002.tgz
	tar xzvf zcs-*
	echo "Installing Zimbra Collaboration just the Software"
	cd /tmp/zcs/zcs-* && ./install.sh -s < /tmp/zcs/installZimbra-keystrokes
	echo "Installing Zimbra Collaboration injecting the configuration"
	/opt/zimbra/libexec/zmsetup.pl -c /tmp/zcs/installZimbraScript
fi
if [[ `lsb_release -rs` == "14.04" ]]; then
	echo "Downloading Zimbra Collaboration 8.8.10 for Ubuntu 16.04"
	wget https://files.zimbra.com/downloads/8.8.10_GA/zcs-8.8.10_GA_3039.UBUNTU14_64.20180928094617.tgz
	tar xzvf zcs-*
	echo "Installing Zimbra Collaboration just the Software"
	cd /tmp/zcs/zcs-* && ./install.sh -s < /tmp/zcs/installZimbra-keystrokes
	echo "Installing Zimbra Collaboration injecting the configuration"
	/opt/zimbra/libexec/zmsetup.pl -c /tmp/zcs/installZimbraScript
fi

## Restart Zimbra
su - zimbra -c 'zmcontrol restart'

## Add Crontab for server autostart at startup or reboot 
cat <(crontab -l) <(echo "@reboot su - zimbra -c 'zmcontrol start'") | crontab -

echo "You can access now to your Zimbra Collaboration Server"
echo "Admin Console: https://"$1":7071"
echo "Web Client: https://"$1
