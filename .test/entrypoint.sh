#!/bin/bash -ex

echo "Build SRPM"
chown root. *
rpmbuild -bs *.spec

echo "Build RPM"
yum-builddep -y *.spec
rpmbuild -ba *.spec

echo "Install RPM"
yum install -y  /root/rpmbuild/RPMS/noarch/*.rpm

echo "Start Tomcat"
/usr/libexec/tomcat/server start &

echo "Wait for Tomcat to be ready"
wait-for-it.sh localhost:8080 -- echo "Tomcat is up"

curl -s -I -L localhost:8080/examples/servlets |grep 200
curl -s -I -L localhost:8080/examples/jsp |grep 200
curl -s -I -L localhost:8080/examples/websocket |grep 200
