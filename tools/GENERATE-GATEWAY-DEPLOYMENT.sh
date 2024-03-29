#!/bin/bash
#
# Copyright 2023 Google LLC. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

PROJECT=$(gcloud config get project)
REGION=$(gcloud config get run/region)
ENDPOINT_ADDRESS=https://$(gcloud api-gateway gateways describe bookstore --location ${REGION} --format "value(defaultHostname)")
SERVICE=$(gcloud api-gateway apis describe bookstore --format "value(managedService)")

SPEC_REVISION=$(registry get projects/${PROJECT}/locations/global/apis/bookstore/deployments/backend -o raw | jq .[0].apiSpecRevision -r)
SPEC_REVISION=${SPEC_REVISION#projects/${PROJECT}/locations/global/apis/bookstore/versions/}

cat > gateway-deployment.yaml <<EOF
apiVersion: apigeeregistry/v1
kind: Deployment
metadata:
  name: gateway
  parent: apis/bookstore
  labels:
    platform: apigateway
    apihub-gateway: google-cloud-api-gateway
  annotations:
    apihub-external-channel-name: API Gateway
    region: $REGION
    project: $PROJECT
data:
  displayName: Gateway
  description: An API Gateway deployment of the Bookstore API
  apiSpecRevision: $SPEC_REVISION
  endpointURI: $ENDPOINT_ADDRESS
  externalChannelURI: https://console.cloud.google.com/api-gateway/api/bookstore/servicename/$SERVICE/overview?project=$PROJECT
  intendedAudience: Public
EOF
