#!/bin/bash
echo "$1 subscribed with no spaces: username:$1" >> /var/www/changestaus.log  
ldapadd -x -D "cn=admin,dc=us-west-2,dc=compute,dc=internal" -w mister -f /var/www/newsite/"$1".ldif

guid=$(awk -F: '/'uidNumber'/{print $2}' /var/www/newsite/"$1".ldif)
sudo mkdir /home/"$1"
sudo chown "$guid" /home/"$1"
sudo chmod 700 /home/"$1"