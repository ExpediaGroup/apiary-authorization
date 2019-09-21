#!/bin/bash

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

if [ ! -e /usr/bin/ansible ]; then
    yum -y install ansible python-pip python-boto3
fi