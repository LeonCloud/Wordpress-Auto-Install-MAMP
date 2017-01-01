#!/bin/bash

##############################
# Fork: facelordgists work.
# Version: 1.0
# Date: 1/1/17
# Author: Matteo B.

################
# VARIABLES/ARGUMENTS
################
# information for install

echo "Enter domain name: "
read domain
domain_name="$domain.com"
www_root_dir="$domain_name"
db_name="$domain"
db_user="root"
db_pass="root"


################
# CLEANUP/FORMATTING
################
# make sure mysql user is 14 char or less
db_user=$(echo "$db_user" | cut -c -14)


################
# WORDPRESS
################
echo "** DOWNLOADING WORDPRESS **"
echo ""
# get latest wordpress source
if [ ! -d /Applications/MAMP/Source/ ]; then
mkdir /Applications/MAMP/Source/
fi
cd /Applications/MAMP/Source/
rm -rf wordpress
curl -L -o 'latest.tar.gz' http://wordpress.org/latest.tar.gz
tar -zxf latest.tar.gz wordpress

echo "** COPYING WORDPRESS FILES **"
echo ""
# copy latest source to target local www root folder
mkdir /Applications/MAMP/htdocs/$www_root_dir
cp -R wordpress/* /Applications/MAMP/htdocs/$www_root_dir

echo "** CREATING WP-CONFIG.PHP FILE **"
echo ""
# review config file for default install
cd /Applications/MAMP/htdocs/$www_root_dir
mv wp-config-sample.php wp-config.php
# generate secret-key and replace
curl -L https://api.wordpress.org/secret-key/1.1/salt/ > temp_key
sed -i.bak -e '49d;48r temp_key' wp-config.php && sed -i.bak -e '57,63d' wp-config.php
rm temp_key

echo "** SETTING WP-CONFIG.PHP FILE**"
echo ""
echo "DB NAME: $db_name"
echo "DB USER: $db_user"
echo "DB PASS: $db_pass"
sed -i.bak -e "s/database_name_here/${db_name}/g" wp-config.php && sed -i.bak -e "s/username_here/${db_user}/g" wp-config.php && sed -i.bak -e "s/password_here/${db_pass}/g" wp-config.php
rm wp-config.php.bak

################
# MYSQL
################
# create sql commands for local database & user
qry_create_db="CREATE DATABASE \`$db_name\`;"
qry_grant_user="GRANT ALL ON \`$db_name\`.* TO '$db_user'@'localhost';"
qry_create_user="SET PASSWORD FOR '$db_user'@'localhost' = PASSWORD('$db_pass');"
qry_flush="FLUSH PRIVILEGES;"

# create sql statement
SQL="${qry_create_db}${qry_grant_user}${qry_create_user}${qry_flush}"

echo "** CREATING WORDPRESS DATABASE FROM ARGS **"
echo ""
echo $SQL
echo ""
# execute mysql commands
/Applications/MAMP/Library/bin/mysql -uroot -proot -e "$SQL"

################
# APACHE
################

echo "** RESTART APACHE **"
echo ""
# restart httpd service
sudo /Applications/MAMP/bin/apache2/bin/apachectl restart
