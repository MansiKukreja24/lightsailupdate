#!/bin/bash
sudo apt-get update --assume-yes
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt install mongodb --assume-yes
sudo apt install nodejs --assume-yes
node --version
npm --version
sudo apt-get install git --assume-yes
sudo npm install pm2 -g
#sudo apt update && upgrade
sudo apt install nginx --assume-yes
systemctl start nginx
systemctl enable nginx
apt-get install build-essential --assume-yes
sudo apt install jq -y
sleep 5
cd /var/www/html
rm -f *

sudo tee /pipe.sh >/dev/null <<EOE
#!/bin/bash

function funstartserver {
	type=\$(jq -r .deployment_type \${arr1[\$i]}/deploy.json)
        if [ \$type == react ]
        then
                portno=\$(jq -r .port_number \${arr1[\$i]}/deploy.json)
                servname=\$(jq -r .server_name \${arr1[\$i]}/deploy.json)
                servalias=\$(jq -r .server_alias \${arr1[\$i]}/deploy.json)
                cd \${arr1[\$i]}
                npm i
                npm run-script build
                pm2 serve build \$portno --spa
                cd
        elif [ \$type == node ]
        then
                filename=\$(jq -r .file_name \${arr1[\$i]}/deploy.json)
                nportno=\$(jq -r .port_number \${arr1[\$i]}/deploy.json)
                servname=\$(jq -r .server_name \${arr1[\$i]}/deploy.json)
                servalias=\$(jq -r .server_alias \${arr1[\$i]}/deploy.json)
                cd \${arr1[\$i]}
                npm i
                pm2 start \$filename
                cd
        elif [ \$type == html ]
        then
                servname=\$(jq -r .server_name \${arr1[\$i]}/deploy.json)
                servalias=\$(jq -r .server_alias \${arr1[\$i]}/deploy.json)
        else
                echo "Not an app"
        fi
	systemctl restart nginx
	sleep 2
}

function funcreateconffile {
	type=\$(jq -r .deployment_type \${arr1[\$i]}/deploy.json)
        if [ \$type == react ]
        then
                portno=\$(jq -r .port_number \${arr1[\$i]}/deploy.json)
                servname=\$(jq -r .server_name \${arr1[\$i]}/deploy.json)
                servalias=\$(jq -r .server_alias \${arr1[\$i]}/deploy.json)
                cd \${arr1[\$i]}
                sudo tee -a  /etc/nginx/sites-available/\${arr2[\$i]}.conf >/dev/null << EOF
                <VirtualHost *:80>
                ServerName \$servname 
                ServerAlias \$servalias
                ProxyRequests Off 
                ProxyPreserveHost On 
                ProxyVia Full 
                <Proxy *>
                        Require all granted 
                </Proxy>         

                <Location />
                ProxyPass  http://127.0.0.1:\$portno/
                ProxyPassReverse http://127.0.0.1:\$portno/
                </Location>

                <Directory "\${arr1[\$i]}"> 
                AllowOverride All
                </Directory>
                </VirtualHost>

                <VirtualHost *:443>
                ServerName \$servname 
                ServerAlias \$servalias
                ProxyRequests Off 
                ProxyPreserveHost On 
                ProxyVia Full 
                <Proxy *>
                        Require all granted 
                </Proxy>         

                <Location />
                ProxyPass  http://127.0.0.1:\$portno/
                ProxyPassReverse http://127.0.0.1:\$portno/
                </Location>

                <Directory "\${arr1[\$i]}"> 
                AllowOverride All
                </Directory>
                </VirtualHost>
EOF
                cd
        elif [ \$type == node ]
        then
                filename=\$(jq -r .file_name \${arr1[\$i]}/deploy.json)
                nportno=\$(jq -r .port_number \${arr1[\$i]}/deploy.json)
                servname=\$(jq -r .server_name \${arr1[\$i]}/deploy.json)
                servalias=\$(jq -r .server_alias \${arr1[\$i]}/deploy.json)
                cd \${arr1[\$i]}
                sudo tee -a  /etc/nginx/sites-available/\${arr2[\$i]}.conf >/dev/null << EOF
                <VirtualHost *:80>
                ServerName \$servname 
                ServerAlias \$servalias
                ProxyRequests Off 
                ProxyPreserveHost On 
                ProxyVia Full 
                <Proxy *>
                        Require all granted 
                </Proxy>         

                <Location />
                ProxyPass  http://127.0.0.1:\$nportno/
                ProxyPassReverse http://127.0.0.1:\$nportno/
                </Location>

                <Directory "\${arr1[\$i]}"> 
                AllowOverride All
                </Directory>
                </VirtualHost>

                <VirtualHost *:443>
                ServerName \$servname 
                ServerAlias \$servalias
                ProxyRequests Off 
                ProxyPreserveHost On 
                ProxyVia Full 
                <Proxy *>
                        Require all granted 
                </Proxy>         

                <Location />
                ProxyPass  http://127.0.0.1:\$nportno/
                ProxyPassReverse http://127.0.0.1:\$nportno/
                </Location>

                <Directory "\${arr1[\$i]}"> 
                AllowOverride All
                </Directory>
                </VirtualHost>
EOF
                cd
        elif [ \$type == html ]
        then
                servname=\$(jq -r .server_name \${arr1[\$i]}/deploy.json)
                servalias=\$(jq -r .server_alias \${arr1[\$i]}/deploy.json)
                sudo tee -a  /etc/nginx/sites-available/\${arr2[\$i]}.conf >/dev/null << EOF
                <VirtualHost *:80>
                # This is the name of the vhost.
                ServerName \$servname
                # These are alternative names for this same vhost.
        # We put the other domains here. They will all go to the same place.
                ServerAlias \$servalias
                # Directory where the website code lives.
                DocumentRoot \${arr1[\$i]}
                ErrorLog \${NGINX_LOG_DIR}/error.log
                CustomLog \${NGINX_LOG_DIR}/access.log combined
                <Directory />
                        Options FollowSymLinks
                        AllowOverride All
                </Directory>
                </VirtualHost>


                <VirtualHost *:443>
                # This is the name of the vhost.
        ServerName \$servname
        # These are alternative names for this same vhost.
        # We put the other domains here. They will all go to the same place.
        ServerAlias \$servalias
        # Directory where the website code lives.
        DocumentRoot \${arr1[\$i]}
        ErrorLog \${NGINX_LOG_DIR}/error.log
        CustomLog \${NGINX_LOG_DIR}/access.log combined
        <Directory />
                Options FollowSymLinks
                AllowOverride All
        </Directory>
        </VirtualHost>
EOF
        else
                echo "Not an app"
        fi
	sudo a2enmod proxy
	sudo a2enmod proxy_http
	sudo a2enmod proxy_balancer
	sudo a2enmod lbmethod_byrequests
	sudo a2ensite \${arr2[\$i]}.conf
	sudo a2dismod --force autoindex
	systemctl restart apache2
	sleep 2
}
  
c=\$(ls -l /var/www/html/ | wc -l)
if [ \$c -gt 1 ]
then
cd /var/www/html
gc=\$(git pull | wc -l)
if [ \$gc -gt 1 ]
then

arr1=(/var/www/html/*/)
cd /var/www/html/
arr2=(*/)
for(( i=0; i<\${#arr2[@]}; i++ ))
do
arr2[\$i]=\$(echo \${arr2[\$i]} | tr -d "/")
done
echo \${arr1[@]}
total=\${#arr1[@]}
if [ -f /etc/.pm2/pm2.pid ]
then
	kill \$(cat /etc/.pm2/pm2.pid | grep -o -E '[0-9]+')
fi
if [ -f /root/.pm2/pm2.pid ]
then
kill \$(cat /root/.pm2/pm2.pid | grep -o -E '[0-9]+')
fi
pm2 delete all
for(( i=0; i<\$total; i++ ))
do
        funstartserver
done
for(( i=0; i<\$total; i++ ))
do
	if [ -f /etc/nginx/sites-available/\${arr2[\$i]}.conf ]
	then
		echo "File Exist"
		continue
	else
		touch /etc/nginx/sites-available/\${arr2[\$i]}.conf
	fi 
        funcreateconffile
done


fi
else
echo "Empty"
gitpassword="changegithubpassword"
gitusername="changegithubusername"
reponame="changegithubreponame"
git -C /var/www/html clone https://\${gitusername}:\${gitpassword}@github.com/\${gitusername}/\${reponame} .

arr1=(/var/www/html/*/)
cd /var/www/html/
arr2=(*/)
for(( i=0; i<\${#arr2[@]}; i++ ))
do
arr2[\$i]=\$(echo \${arr2[\$i]} | tr -d "/")
done
echo \${arr1[@]}
total=\${#arr1[@]}

for(( i=0; i<\$total; i++ ))
do 
        funstartserver
done


for(( i=0; i<\$total; i++ ))
do
	if [ -f /etc/nginx/sites-available/\${arr2[\$i]}.conf ]
	then
		echo "File Exist"
		continue
	else
		touch /etc/nginx/sites-available/\${arr2[\$i]}.conf
	fi
	funcreateconffile 
done

fi
EOE

cronvar="changecronExpression"


cd /
chmod +x pipe.sh
./pipe.sh
sleep 10

rm -rfv /etc/crontab

sudo tee /etc/crontab >/dev/null <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

17 *    * * *   root    cd / && run-parts --report /etc/cron.hourly
25 6    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6    * * 7   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6    1 * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )
$cronvar root /pipe.sh

EOF


