#!/bin/bash -x

set -e

AWS_PROFILE=$1
ECR_REPOSITORY=$2
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

cd $(dirname $0)

aws ecr get-login-password --region ap-northeast-1 \
| docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com

docker build --platform linux/amd64 -f ../src/ecs/Dockerfile ../src/ecs/ -t example
docker tag $ECR_REPOSITORY:latest $AWS_ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/$ECR_REPOSITORY:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.ap-northeast-1.amazonaws.com/$ECR_REPOSITORY:latest
