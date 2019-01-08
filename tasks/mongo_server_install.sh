#!/bin/sh

yum clean all
yum install -y mongodb-enterprise

if [ $? -eq 0 ]; then
  echo "Install complete"
else
  echo "Install failed"
fi