```
# build and push
ACCOUNT_ID=
aws ecr get-login-password --region ap-northeast-1 --profile admin | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com
docker build -t ${ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/app:latest .
docker push ${ACCOUNT_ID}.dkr.ecr.ap-northeast-1.amazonaws.com/app:latest
```

```
# force deployment
SERVICE=
CLUSTER=
aws ecs update-service \
    --service ${SERVICE} \
    --cluster ${CLUSTER} \
    --force-new-deployment
```