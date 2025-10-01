#!/bin/bash
set -e
set -u
set -o pipefail

# run from the root of the project

# Create directory for IAM policies if it doesn't exist
mkdir -p terraform/iam-policies

# Download the IAM policy for the AWS Load Balancer Controller
curl -o terraform/iam-policies/aws-load-balancer-controller-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.4/docs/install/iam_policy.json
