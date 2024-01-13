#!/bin/bash

set -e

(cd ~/src/terraform-provider-aws && make build)
(cd ~/src/terraform-template/quick-sight/ && AWS_PROFILE=admin terraform apply -auto-approve)
