#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Color_Text()
{
  echo -e " \e[0;$2m$1\e[0m"
}

Echo_Red()
{
  echo $(Color_Text "$1" "31")
}

Echo_Green()
{
  echo $(Color_Text "$1" "32")
}

Echo_Yellow()
{
  echo $(Color_Text "$1" "33")
}

Echo_Blue()
{
  echo $(Color_Text "$1" "34")
}

Get_Dist_Name()
{
	if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
		DISTRO='CentOS'
		PM='yum'
	elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
		DISTRO='RHEL'
		PM='yum'
	elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
		DISTRO='Aliyun'
		PM='yum'
	elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
		DISTRO='Fedora'
		PM='yum'
	elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
		DISTRO='Amazon'
		PM='yum'
	elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
		DISTRO='Debian'
		PM='apt'
	elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
		DISTRO='Ubuntu'
		PM='apt'
	elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
		DISTRO='Raspbian'
		PM='apt'
	elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
		DISTRO='Deepin'
		PM='apt'
	elif grep -Eqi "Mint" /etc/issue || grep -Eq "Mint" /etc/*-release; then
		DISTRO='Mint'
		PM='apt'
	elif grep -Eqi "Kali" /etc/issue || grep -Eq "Kali" /etc/*-release; then
		DISTRO='Kali'
		PM='apt'
	else
		DISTRO='unknow'
	fi
}

Set_Timezone()
{
	Echo_Blue "Setting timezone..."
	rm -rf /etc/localtime
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

Install_NTP()
{
	if [ "$PM" = "yum" ]; then
		Echo_Blue "[+] Installing ntp..."
		yum install -y ntp
		ntpdate -u pool.ntp.org
		date
		start_time=$(date +%s)
	elif [ "$PM" = "apt" ]; then
		apt update -y
		Echo_Blue "[+] Installing ntp..."
		apt install -y ntpdate
		ntpdate -u pool.ntp.org
		date
		start_time=$(date +%s)
	fi
}

Disable_Selinux()
{
	if [ -s /etc/selinux/config ]; then
		sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
	fi
}

Add_Iptables_Rules()
{
	#add iptables firewall rules
	if [ -s /sbin/iptables ]; then
		/sbin/iptables -I INPUT 1 -i lo -j ACCEPT
		/sbin/iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT
		/sbin/iptables -I INPUT 3 -p tcp --dport 22:65535 -j ACCEPT
		/sbin/iptables -I INPUT 4 -p udp --dport 22:65535 -j ACCEPT
		/sbin/iptables -I INPUT 5 -p icmp -m icmp --icmp-type 8 -j ACCEPT
		if [ "$PM" = "yum" ]; then
			service iptables save
			if [ -s /usr/sbin/firewalld ]; then
				systemctl stop firewalld
				systemctl disable firewalld
			fi
		elif [ "$PM" = "apt" ]; then
			iptables-save > /etc/iptables.rules
			cat >/etc/network/if-post-down.d/iptables<<EOF
#!/bin/bash
iptables-save > /etc/iptables.rules
EOF
			chmod +x /etc/network/if-post-down.d/iptables
			cat >/etc/network/if-pre-up.d/iptables<<EOF
#!/bin/bash
iptables-restore < /etc/iptables.rules
EOF
			chmod +x /etc/network/if-pre-up.d/iptables
		fi
	fi
}

INTERFACE_Selection()
{
	if [ -z ${INTERFACE} ]; then
		Echo_Yellow "Please choose your interface."
		echo "1: modwebapi"
		echo "2: glzjinmod"
		read -p "Enter your choice (1, 2): " INTERFACE
	fi
}


API_Input()
{
	General_Input
	if [ -z ${WEBAPI_URL} ]; then
		read -p "Please input your WEBAPI_URL: " WEBAPI_URL
	fi
	if [ -z ${WEBAPI_TOKEN} ]; then
		read -p "Please input your WEBAPI_TOKEN: " WEBAPI_TOKEN
	fi
}

DB_Input()
{
	General_Input
	if [ -z ${MYSQL_HOST} ]; then
		read -p "Please input your MYSQL_HOST: " MYSQL_HOST
	fi
	if [ -z ${MYSQL_PORT} ]; then
		read -p "Please input your MYSQL_PORT: " MYSQL_PORT
	fi
	if [ -z ${MYSQL_USER} ]; then
		read -p "Please input your MYSQL_USER: " MYSQL_USER
	fi
	if [ -z ${MYSQL_PASS} ]; then
		read -p "Please input your MYSQL_PASS: " MYSQL_PASS
	fi
	if [ -z ${MYSQL_DB} ]; then
		read -p "Please input your MYSQL_DB: " MYSQL_DB
	fi

<<'COMMENT'
	if [ -z ${MYSQL_SSL_ENABLE} ]; then
		read -p "Please input your MYSQL_SSL_ENABLE: " MYSQL_SSL_ENABLE
	fi
	if [ -z ${MYSQL_SSL_CA} ]; then
		read -p "Please input your MYSQL_SSL_CA: " MYSQL_SSL_CA
	fi
	if [ -z ${MYSQL_SSL_CERT} ]; then
		read -p "Please input your MYSQL_SSL_CERT: " MYSQL_SSL_CERT
	fi
	if [ -z ${MYSQL_SSL_KEY} ]; then
		read -p "Please input your MYSQL_SSL_KEY: " MYSQL_SSL_KEY
	fi
COMMENT
}

General_Input()
{
	if [ -z ${NODE_ID} ]; then
		read -p "Please input your NODE_ID: " NODE_ID
	fi
	if [ -z ${SPEEDTEST} ]; then
		read -p "Please input your SPEEDTEST: " SPEEDTEST
	fi
	if [ -z ${CLOUDSAFE} ]; then
		read -p "Please input your CLOUDSAFE: " CLOUDSAFE
	fi
	if [ -z ${ANTISSATTACK} ]; then
		read -p "Please input your ANTISSATTACK: " ANTISSATTACK
	fi
	if [ -z ${AUTOEXEC} ]; then
		read -p "Please input your AUTOEXEC: " AUTOEXEC
	fi
	if [ -z ${MU_SUFFIX} ]; then
		read -p "Please input your MU_SUFFIX: " MU_SUFFIX
	fi
	if [ -z ${MU_REGEX} ]; then
		read -p "Please input your MU_REGEX: " MU_REGEX
	fi
	if [ -z ${Restart} ]; then
		read -p "Please input restart hour: " Restart
	fi
}

Install_Node()
{
	Press_Install
	Kill_PM

	if [ "$PM" = "yum" ]; then
		CentOS_InstallNode
	elif [ "$PM" = "apt" ]; then
		Debian_InstallNode
	fi
}

Press_Install()
{
	if [ -z ${Auto_Install} ]; then
		echo ""
		Echo_Green "Press any key to install...or Press Ctrl+c to cancel"
		OLDCONFIG=`stty -g`
		stty -icanon -echo min 1 time 0
		dd count=1 2>/dev/null
		stty ${OLDCONFIG}
	fi
}

Kill_PM()
{
	if ps aux | grep "yum" | grep -qv "grep"; then
		if [ -s /usr/bin/killall ]; then
			killall yum
		else
			kill `pidof yum`
		fi
	elif ps aux | grep "apt" | grep -qv "grep"; then
		if [ -s /usr/bin/killall ]; then
			killall apt
		else
			kill `pidof apt`
		fi
	fi
}

CentOS_InstallNode()
{
	Echo_Blue "[+] Installing requirements..."
	yum -y install wget git epel-release
	yum -y install python-pip python-devel libffi-devel openssl-devel
	pip install --upgrade pip
	pip install --upgrade setuptools

	Echo_Blue "[+] Installing Libsodium..."
	yum -y groupinstall "Development Tools"
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.17/libsodium-1.0.17.tar.gz
	tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	cd ../

	Echo_Blue "[+] Installing Shadowsocks..."
	git clone https://github.com/dump0/shadowsocks
	cd shadowsocks
	pip install -r requirements.txt
	cd ../

	Echo_Blue "[+] Stopping Firewall..."
	systemctl stop firewalld.service
	systemctl disable firewalld.service

	Echo_Blue "[+] Installing Crontab..."
	yum -y install vixie-cron crontabs
	crontabs_path="/var/spool/cron/root"

	Echo_Blue "[+] Installing Supervisor..."
	yum -y install supervisor
	supervisord_path="/etc/supervisord.conf"
	chkconfig supervisord on
}

Debian_InstallNode()
{
	Echo_Blue "[+] Installing Requires..."
	apt -y update
	apt -y install wget git
	apt -y install python-pip python-dev libffi-dev libssl-dev
	pip install --upgrade pip
	sed -i "s#from pip import main#from pip._internal import main#" /usr/bin/pip
	pip install --upgrade setuptools

	Echo_Blue "[+] Installing Libsodium..."
	apt -y install build-essential
	wget https://github.com/jedisct1/libsodium/releases/download/1.0.17/libsodium-1.0.17.tar.gz
	tar xf libsodium-1.0.17.tar.gz && cd libsodium-1.0.17
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	cd ../

	Echo_Blue "[+] Installing Shadowsocks..."
	git clone https://github.com/dump0/shadowsocks
	cd shadowsocks
	pip install -r requirements.txt
	cd ../

	Echo_Blue "[+] Installing Crontab..."
	apt -y install cron
	crontabs_path="/var/spool/cron/crontabs/root"

	Echo_Blue "[+] Installing Supervisor..."
	apt -y install supervisor
	supervisord_path="/etc/supervisor/supervisord.conf"
}

Set_Node()
{
	Echo_Blue "[+] Setting Node..."
	cd shadowsocks
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json

	#General_Input
	sed -i "s#NODE_ID = 1#NODE_ID = ${NODE_ID}#" userapiconfig.py
	sed -i "s#SPEEDTEST = 6#SPEEDTEST = ${SPEEDTEST}#" userapiconfig.py
	sed -i "s#CLOUDSAFE = 1#CLOUDSAFE = ${CLOUDSAFE}#" userapiconfig.py
	sed -i "s#ANTISSATTACK = 0#ANTISSATTACK = ${ANTISSATTACK}#" userapiconfig.py
	sed -i "s#AUTOEXEC = 0#AUTOEXEC = ${AUTOEXEC}#" userapiconfig.py
	sed -i "s#MU_SUFFIX = 'zhaoj.in'#MU_SUFFIX = '${MU_SUFFIX}'#" userapiconfig.py
	sed -i "s#MU_REGEX = '%5m%id.%suffix'#MU_REGEX = '${MU_REGEX}'#" userapiconfig.py
	
	if [ ${INTERFACE} = '1' ]; then
		#API_Input
		if 
		if [ "${WEBAPI_URL}" = "" ]; then
			sed -i "s#WEBAPI_URL = 'https://zhaoj.in'#WEBAPI_URL = '${WEBAPI_URL}'#" userapiconfig.py
		fi
		if [ "${WEBAPI_TOKEN}" = "" ]; then
			sed -i "s#WEBAPI_TOKEN = 'glzjin'#WEBAPI_TOKEN = '${WEBAPI_TOKEN}'#" userapiconfig.py
		fi
	else
		sed -i "s#API_INTERFACE = 'modwebapi'#API_INTERFACE = 'glzjinmod'#" userapiconfig.py
		#DB_Input
		if [ "${MYSQL_HOST}" = "" ]; then
			sed -i "s#MYSQL_HOST = '127.0.0.1'#MYSQL_HOST = '${MYSQL_HOST}'#" userapiconfig.py
		fi
		if [ "${MYSQL_PORT}" = "" ]; then
			sed -i "s#MYSQL_PORT = 3306#MYSQL_PORT = ${MYSQL_PORT}#" userapiconfig.py
		fi
		if [ "${MYSQL_USER}" = "" ]; then
			sed -i "s#MYSQL_USER = 'ss'#MYSQL_USER = '${MYSQL_USER}'#" userapiconfig.py
		fi
		if [ "${MYSQL_PASS}" = "" ]; then
			sed -i "s#MYSQL_PASS = 'ss'#MYSQL_PASS = '${MYSQL_PASS}'#" userapiconfig.py
		fi
		if [ "${MYSQL_DB}" = "" ]; then
			sed -i "s#MYSQL_DB = 'shadowsocks'#MYSQL_DB = '${MYSQL_DB}'#" userapiconfig.py
		fi
	fi

	cd ../
}

Set_Crontab()
{
	if [ "${Restart}" != "" ]; then
		echo "0 ${Restart} * * * supervisorctl reload" >> ${crontabs_path}
		/sbin/service crond restart
	fi
}

Set_Supervisor()
{
	sed -i "s#'minfds=1024  '#'minfds=512000'#" ${supervisord_path}
	echo "[program:shadowsocks]" >> ${supervisord_path}
	echo "command = python $(pwd)/shadowsocks/server.py" >> ${supervisord_path}
	echo "user = root" >> ${supervisord_path}
	echo "autostart = true" >> ${supervisord_path}
	echo "autorestart = true" >> ${supervisord_path}
}

Set_openfiles()
{
	sed -i "/hard nofile/d" /etc/security/limits.conf
	sed -i "/soft nofile/d" /etc/security/limits.conf
	echo "* hard nofile 512000" >> /etc/security/limits.conf
	echo "* soft nofile 512000" >> /etc/security/limits.conf
}

Install_BBR()
{
	wget --no-check-certificate https://github.com/dump0/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
}


# Check if user is root
if [ $(id -u) != "0" ]; then
	echo "Error: You must be root to run this script, please use root to install node"
	exit 1
fi

Get_Dist_Name

if [ "${DISTRO}" = "unknow" ]; then
	Echo_Red "Unable to get Linux distribution name, or do NOT support the current distribution."
	exit 1
fi

clear
echo "+------------------------------------------------------------------------+"
echo "|             A tool to auto-install  backend-node for SSPanel           |"
echo "+------------------------------------------------------------------------+"
echo "|        For more information please visit https://github.com/dump0      |"
echo "+------------------------------------------------------------------------+"


INTERFACE_Selection

case "${INTERFACE}" in
	1)
		echo "You choose modwebapi"
		General_Input
		API_Input
		Install_Node
		;;
	2)
		echo "You choose glzjinmod"
		General_Input
		DB_Input
		Install_Node
		;;
	*)
		echo "Error: Wrong input"
		exit 1
esac

Set_Node
Set_Crontab
Set_Supervisor
Install_NTP
Set_Timezone
Set_openfiles
Disable_Selinux
Add_Iptables_Rules
Install_BBR
reboot
