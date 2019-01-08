#!/bin/sh

user=$PT_user
passwd=$PT_passwd
port=$PT_port

mongo admin --port $port --eval "db.createUser( { 'user': '${user}', 'pwd': '${passwd}', roles: [ { 'db': 'admin', 'role': 'root'} ] } )"
