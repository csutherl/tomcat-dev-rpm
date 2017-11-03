FROM centos

RUN yum install -y epel-release \
 && yum install -y git tito rpm-build rpmdevtools \
 && yum clean all

RUN git config --global user.email "travis@travis-ci.org" \
 && git config --global user.name "Travis CI"

