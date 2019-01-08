#!/bin/sh

yum update -y
if [ $? -eq 0 ]; then
  echo "Update complete"
else
  echo "Update failed"
fi