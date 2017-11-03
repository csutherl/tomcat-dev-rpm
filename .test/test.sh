#!/bin/bash
set -ex

# Support both centos (yum) and Fedora (dnf)
sed -i "s/FROM .*/FROM $OS/g" .test/Dockerfile
if [[ "$OS" =~ ^fedora.* ]]; then
  sed -i "s/yum-/dnf /g" .test/*
  sed -i "s/yum/dnf/g" .test/*
fi

# Travis is using Ubuntu, use Docker to get RPM build tools
docker build -t rpmbuilder .test/
docker run -w /root/rpmbuild/SOURCES/ -it -v `pwd`:/root/rpmbuild/SOURCES/ rpmbuilder
