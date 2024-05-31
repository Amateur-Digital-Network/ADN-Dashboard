#!/bin/bash

echo Installing acme.sh...
curl https://get.acme.sh |sh -s email=$1 &&

echo Requesting and installing cettificates...
/root/.acme.sh/acme.sh --issue -d $2 -w /var/www/html/ && 

 /root/.acme.sh/acme.sh --install-cert -d $2 \
--cert-file      /opt/apachecerts/cert.pem  \
--key-file       /opt/apachecerts/key.pem  \
--fullchain-file /opt/apachecerts/chain.pem \
--reloadcmd     "apachectl restart"