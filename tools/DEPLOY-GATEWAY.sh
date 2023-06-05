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

set -e

API_ID=bookstore
DEPLOYMENT_ID=backend

ADDRESS=$(registry get apis/${API_ID}/deployments/${DEPLOYMENT_ID} -o raw | jq .[0].endpointUri -r)
ADDRESS=${ADDRESS#https://}

SPEC=$(registry get apis/${API_ID}/deployments/${DEPLOYMENT_ID} -o raw | jq .[0].apiSpecRevision -r)

PROJECT=$(gcloud config get project)
REGION=$(gcloud config get run/region)

cat > api_config.yaml <<EOF
# The configuration schema is defined by the service.proto file.
# https://github.com/googleapis/googleapis/blob/master/google/api/service.proto

type: google.api.Service
config_version: 3
name: "*.apigateway.$PROJECT.cloud.goog"
title: API Gateway + Cloud Run gRPC
apis:
  - name: examples.bookstore.v1.Bookstore
usage:
  rules:
  - selector: "*"
    allow_unregistered_calls: true
backend:
  rules:
  - selector: "*"
    address: grpcs://$ADDRESS
EOF

registry-experimental compute descriptor apis/${API_ID}/versions/v1/specs/protos
registry get apis/${API_ID}/versions/v1/specs/protos/artifacts/descriptor -o contents > descriptor.pb

gcloud api-gateway api-configs create ${API_ID} --api=${API_ID} --project=${PROJECT} --grpc-files=descriptor.pb,api_config.yaml
gcloud api-gateway gateways create ${API_ID} --api=${API_ID} --api-config=${API_ID} --location=${REGION} --project=${PROJECT}

