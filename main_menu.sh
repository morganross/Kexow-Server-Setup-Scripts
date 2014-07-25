#!/bin/bash
ZFILE="/etc/bind/zones/kexow.com.zone"
IP_LIST="/etc/bind/list.txt"
LOG="/var/log/named/queries.log"
#source aws_bind_ip.sh
do_exit=0
farray=(named.conf.log pk.pem cert.pem creds.txt aws_bind_ip.sh named.conf.local)
for FILE in "${farray[@]}"
do
	if [ ! -e $FILE ] ;then
		echo "The required files $FILE does not exist"
		do_exit=1
	fi
done
if [ $do_exit -eq 1 ];then
	exit
fi

source aws_bind_ip.sh
while true;do
	echo "*******************************************************************"
	echo "1. Install ec2-api-tools"
	echo "2. Install bind9 package"
	echo "3. Restart bind9 server"
	echo "4. Copy keypair files export environment variable to current shell"
	echo "5. Monitor the Log file [will not return menu press ctrl+c to exit]"
	echo "6. Copy the necessary file for aws-ec2 tools"
	echo "7. Add aws-ec2 variables your login shell [$HOME/.bashrc]"
	echo "8. Populate list.txt with all existing spot instance"
	echo "9. Run the LDAP script"
	echo "Press any other to Exit"
	echo "*******************************************************************"
	echo -n "Enter your choice :"
	read choice
case "$choice" in
"1")
	aws_install
	sleep 2
   ;;
"2")
    bind9_install
    restart_bind
    sleep 2
    ;;
"3")
    restart_bind
    sleep 2
    ;;

"4")
    aws_setup
    sleep 2
    ;;
"5")
    check_log_file
    sleep 2
    ;;
"6")
    copy_aws_ec2_files
    sleep 2
    ;;
"7")
    export_aws_ec2_env
    sleep 2
    ;;
"8")
    aws_get_all_ip
    sleep 2
    ;;
"9")
    run_ldap_func
    sleep 2
    ;;

*)
    echo "exit from menu"
    break
    ;;
esac
done