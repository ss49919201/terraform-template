FROM golang:1.20-alpine

WORKDIR /app

COPY go.* ./
RUN go mod download

COPY . ./

# ECS or Lambda へのデプロイを想定しているので、GOOS=linux
RUN GOOS=linux go build -o /main

CMD [ "/main" ]
