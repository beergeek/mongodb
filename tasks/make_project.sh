#!/bin/sh

OPS_MANAGER_URL=PT_ops_manager_url
PROJECT_NAME=PT_project_name
ORG_ID=PT_org_id
CA_CERT_PATH=PT_curl_ca_cert_path
USERNAME=PT_curl_username
TOKEN=PT_curl_token

if [ $CA_CERT_PATH ]
then
  CA_OPTION="--cacert ${CA_CERT_PATH}"
fi

curl -u ${USERNAME}:${TOKEN} $CA_OPTION -X PUT  -H "Content-Type: application/json" "${OPS_MANAGER_URL}/api/public/v1.0/groups/?pretty=true"--digest  -d \'{"name": "${PROJECT_NAME}", "orgId": "${ORG_ID}"}\'