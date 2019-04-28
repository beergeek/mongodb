#!/bin/bash

username=$PT_username

if id "$username" >/dev/null 2>&1; then
  echo "User exists"
else
  echo "Creating user"
  adduser -s /bin/false -r -m -d /var/lib/mongo $username
fi