#!/bin/bash

aws_install () {
sudo perl -pi.orig -e   'next if /-backports/; s/^# (deb .* multiverse)$/$1/'   /etc/apt/sources.list
sudo apt-add-repository ppa:awstools-dev/awstools
sudo apt-get update
sudo apt-get install ec2-api-tools
if [ $? -ne 0 ];then
	echo "Fail to install the ec2-api-tools"
else
	echo "Successfully installed ec2-api-tools"
fi
}

copy_aws_ec2_files () {

if [ ! -e $HOME/pk.pem ]; then
	cp -f pk.pem $HOME
	echo "copied pk.pem file to $HOME"    
fi
if [ ! -e $HOME/creds.txt ];then
	cp -f creds.txt $HOME
	echo "copied creds.txt file to $HOME"
fi

if [ ! -e $HOME/cert.pem ];then
	cp -f cert.pem $HOME
	echo "copied cert.pem file to $HOME"
fi

}

aws_setup () {
	copy_aws_ec2_files
	export EC2_URL=https://ec2.us-west-2.amazonaws.com
	export EC2_PRIVATE_KEY=$(echo $HOME/pk.pem)
	export EC2_CERT=$(echo $HOME/cert.pem)
	export AWS_CREDENTIAL_FILE=$HOME/creds.txt
}

aws_get_all_ip () {

echo "Script trying to get all IP from ec2-spot-instance"
>$IP_LIST
aws_setup
echo "list.txt is null populate existing instance IP"
ip_address=$(ec2-describe-instances  | awk '/INSTANCE/{print $14}')
IFS=$'\n'
for IP in $ip_address
do
	echo "Got IP from ec2 and IP address $IP END"
       	echo $IP >> $IP_LIST
done

}

aws_check_newip () {
request_id=$1
echo " $LCOUNT aws check new ip has started, script will request new instace if under 4 entries in list"
aws_setup
LCOUNT=$(wc -l $IP_LIST | awk '{print $1}')
#count the IP address if it is zero then populate all the instance IPs to list.txt
if [ "$LCOUNT" -eq 0 ]; then
		echo "list.txt $LCOUNTis null populate existing instance IP"
              IFS=$'\n'
                for IP in $ip_address
                do
        		echo "Got IP from ec2 and IP address $IP END"
        		echo $IP >> $IP_LIST
		done
#If the count is less then 4 and greater than one then create spot instance and wait till the state changed to active
#Once it is active then get IP address and add to list.txt
elif [ "$LCOUNT" -le 4 ] && [ "$LCOUNT" -ge 1 ];then
	echo "list has between 1 and 4 entries, Creating instance $LCOUNT "
	sir=$(ec2-request-spot-instances ami-aa39599a -p 0.006 -k ssdkingstong -t t1.micro | grep -o -P '.{0,0}sir-.{0,8}')
	echo "$LCOUNT Instance info $sir"
	sleep 5
	while true;do
		state=$(ec2-describe-spot-instance-requests $sir | awk '{print $6}')
		echo "State is $state"
        	if [ "$state"  = "active" ];then
                	break
		else
			echo "waiting for spot to become instace, going sleep 13 seconds"
			sleep 13
        	fi
	done
	instance_id=$(ec2-describe-spot-instance-requests $sir | awk '{print $8}')
        ip_address=`ec2-describe-instances $instance_id | awk '/INSTANCE/{print $14}'`
        echo "Got IP from ec2 and IP address $ip_address"
        echo $ip_address >> $IP_LIST
fi

}

bind9_install () {

sudo apt-get -y install bind9
if [ $? -ne 0 ]; then
	echo "Failed to install bind9"
	return 1
fi
#configure log file location
echo -e "\n Copy named.conf.local file to /etc/bind directory"
sudo cp -f named.conf.local /etc/bind

if [ ! -e /etc/bind/named.conf.log ]; then
	sudo cp -f named.conf.log /etc/bind/named.conf.log
else
	echo -en "\n named.conf.log already exists. Do you want overwrite? (y/n): "
        read overwrite
        if [ "$overwrite" = "y" ]; then
		sudo cp -f named.conf.log /etc/bind/named.conf.log
        fi
fi

#zones directory and log file creation
if [ ! -d /etc/bind/zones ]; then
	echo -e "\n Create zones directory and copy necessary files"
	sudo mkdir /etc/bind/zones
	sudo chmod a+w /etc/bind/zones
fi
cp -f kexow.com.zone /etc/bind/zones
cp -f rev.102.254.54.in-addr.arpa /etc/bind/zones
sudo touch /etc/bind/list.txt
sudo chmod 777 /etc/bind/list.txt

if [ ! -e /var/log/named ]; then
	sudo mkdir /var/log/named
fi
sudo touch /var/log/named/bind.log /var/log/named/queries.log /var/log/named/security_info.log /var/log/named/update_debug.log
sudo chmod 777 /var/log/named/queries.log
sudo chmod 777 /var/log/named/bind.log
sudo chmod 777 /var/log/named/security_info.log
sudo chmod 777 /var/log/named/update_debug.log


#Enable log file configuration in named.conf
if ! grep -q named.conf.log /etc/bind/named.conf; then
	sudo echo 'include "/etc/bind/named.conf.log";' >> /etc/bind/named.conf
	echo -e "\n include named.conf.log in named.conf..."
else
	echo -e "\n named.conf.log already in named.conf"
fi
       	echo -e "Successfully installed bind9"

}

changeIP() {
if [ -e $ZFILE ] || [ -e $IP_LIST ];then
	echo "Delete the last line of the $ZFILE"
        sudo sed -i -e "$ d"  $ZFILE
        NEW_IP=$(head -n 1 $IP_LIST)
        sudo echo "connect IN A $NEW_IP" >>$ZFILE
	echo "new zone written with $NEW_IP Delete the First line of the $IP_LIST"
        sudo sed -i -e "1 d" $IP_LIST

else
	echo "Fail to find the $ZFILE or $IP_LIST"
	return 1
fi
	return 0
}

restart_bind () {
	sudo /etc/init.d/bind9 restart > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Failed to restart the bind9 server"
		return 1
	else
		echo "Successfully restarted bind9 server"
		return 0
	fi
}


check_log_file () {
if [ -e $LOG ]; then
      #sudo mv $LOG $LOG.$$
      #sudo touch $LOG
      sudo chmod 777 $LOG
tail -F $LOG |while read LINE;do
	if [[ "${LINE}" =~ 'connect' ]]; then
		echo '
______  _   _  _____  ______  _____  _   _  _____  _____ ______ 
|  _  \| \ | |/  ___| | ___ \|_   _|| \ | ||  __ \|  ___||  _  \
| | | ||  \| |\ `--.  | |_/ /  | |  |  \| || |  \/| |__  | | | |
| | | || . ` | `--. \ |  __/   | |  | . ` || | __ |  __| | | | |
| |/ / | |\  |/\__/ / | |     _| |_ | |\  || |_\ \| |___ | |/ / 
|___/  \_| \_/\____/  \_|     \___/ \_| \_/ \____/\____/ |___/  

'
		changeIP
		echo "called for changeIP"
		ret_code1=$?
		restart_bind
		ret_code2=$?
		if [ $ret_code1 -ne 0 ] || [ $ret_code2 -ne 0 ];then
			echo "Fail to restart bind server or change IP was not happen. Press Control-c to exit"
		else
			echo "we changed ip and it worked with no errors, now we call for aws_check_newip"
			aws_check_newip
		fi

  	fi
done

fi
}


export_aws_ec2_env () {
echo 'export EC2_URL=https://ec2.us-west-2.amazonaws.com' >>$HOME/.bashrc
echo 'export EC2_PRIVATE_KEY=$(echo $HOME/pk.pem)' >>$HOME/.bashrc
echo 'export EC2_CERT=$(echo $HOME/cert.pem)'  >>$HOME/.bashrc
echo 'export AWS_CREDENTIAL_FILE=$HOME/creds.txt' >>$HOME/.bashrc
source $HOME/.bashrc
echo "Successfully set EC2 environment variables"
}

run_ldap_func () {
ldap_base='dc=us-west-2,dc=compute,dc=internal'
ldap_users_base="ou=users,${ldap_base}"
ldap_group_base="ou=groups,${ldap_base}"

sudo apt-get update && sudo apt-get -y install phpldapadmin slapd ldap-utils libnss-ldap libpam-ldap nslcd
sudo sed -i "s/dc=example,dc=com/${ldap_base}/g" /etc/phpldapadmin/config.php

sudo apt-get -y  install nfs-kernel-server
echo " /home   *(rw,sync,no_subtree_check) " >> /etc/exports
sudo exportfs -a

sudo echo "dn: ou=Groups,dc=us-west-2,dc=compute,dc=internal
objectclass: organizationalUnit
objectclass: top
ou: Groups

dn: cn=admins,ou=Groups,dc=us-west-2,dc=compute,dc=internal
cn: admins
gidnumber: 500
objectclass: posixGroup
objectclass: top

dn: ou=Users,dc=us-west-2,dc=compute,dc=internal
objectclass: organizationalUnit
objectclass: top
ou: Users" > /tmp/new.ldif

sudo ldapadd -x -D "cn=admin,dc=us-west-2,dc=compute,dc=internal" -w mkrstaJ&&3KlkFddse3 -f /tmp/new.ldif

}
run_lamp_func () {

sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo passwd ubuntu
sudo service ssh restart
sudo apt-get update
sudo apt-get -y install apache2
sudo apt-get -y install mysql-server libapache2-mod-auth-mysql php5-mysql 
sudo /usr/bin/mysql_secure_installation
sudo apt-get -y install php5 libapache2-mod-php5 php5-mcrypt
sudo service apache2 restart
sudo apt-get -y install phpmyadmin
sudo sed -i '$ a\
Include /etc/phpmyadmin/apache.conf' /etc/apache2/apache2.conf
sudo service apache2 restart

sudo chmod 400 /home/ubuntu/installer/clients.pem
sudo chmod 755 /home/ubuntu/installer/server_script.sh
sudo chmod 4777 /var/www/adscript.sh
sudo chmod 4777 /var/www/xtra/changestaus.sh
sudo chmod 777 /var/log/named/queries.log
sudo chmod 777 /etc/bind/list.txt
sudo chmod 400 /home/ubuntu/installer/clients.pem
sudo chmod 777 -R /var/www/xtra/
sudo chmod 755 /home/ubuntu/installer/server_script.sh
sudo chmod 777 -R /var/www/pyro/


sudo /etc/init.d/apache2 restart
sudo chmod 777 /etc/ssh/ssh_config
sudo echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config



}
