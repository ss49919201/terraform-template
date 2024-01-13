#!/bin/bash
set -e

cd script_go/update_data_set/
AWS_PROFILE=admin go run main.go
