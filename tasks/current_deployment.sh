#!/bin/bash

OPS_MANAGER_URL=$PT_ops_manager_url
PROJECT_ID=$PT_project_id
CA_CERT_PATH=$PT_curl_ca_cert_path
USERNAME=$PT_curl_username
TOKEN=$PT_curl_token

if [ $CA_CERT_PATH ]
then
  CA_OPTION="--cacert ${CA_CERT_PATH}"
fi

set -x
output=$(curl -u ${USERNAME}:${TOKEN} $CA_OPTION -X GET  -H "Content-Type: application/json" "${OPS_MANAGER_URL}/api/public/v1.0/groups/${PROJECT_ID}/automationConfig?pretty=true" --digest)
echo $output