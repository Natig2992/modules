#!/bin/bash
yum -y update
yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<h1>My WebServer with local-IP: $myip</h1>" > /var/www/html/index.html
sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
sudo systemctl start httpd
chkconfig httpd on
