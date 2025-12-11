#!/bin/bash
set -e

/usr/sbin/sshd

# 볼륨 마운트된 웹앱 권한을 tomcat으로 맞춤
chown -R tomcat:tomcat /usr/local/tomcat/webapps || true

exec su -s /bin/bash tomcat -c "catalina.sh run"
