#!/bin/bash

username=$PT_username
password=$PT_password

if id "$username" >/dev/null 2>&1; then
  echo "User exists"
else
  echo "Creating user"
  adduser -u 27017 $username
fi