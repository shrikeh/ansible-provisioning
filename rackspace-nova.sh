#!/usr/bin/env bash

export OS_AUTH_URL='https://identity.api.rackspacecloud.com/v2.0/';
export OS_AUTH_SYSTEM=rackspace;
export OS_REGION_NAME=DFW;
export OS_USERNAME="${RACKSPACE_CLOUD_USERNAME}";
export OS_TENANT_NAME="${RACKSPACE_CLOUD_TENANT_ID}";
export NOVA_RAX_AUTH=1;
export OS_PASSWORD="${RACKSPACE_CLOUD_API_KEY}";
export OS_PROJECT_ID="${RACKSPACE_CLOUD_TENANT_ID}";
export OS_NO_CACHE=1;
