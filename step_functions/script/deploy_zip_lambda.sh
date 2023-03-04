#!/bin/bash -x

set -e

export AWS_PROFILE=$1

function changeDir() {
	cd $(dirname $0)/../src/lambda
}

function build() {
	GOOS=linux GOARCH=amd64 go build -o main main.go
}

function zipBinary() {
	zip main.zip main
}

function upload() {
	aws lambda update-function-code \
	--region ap-northeast-1 \
	--function-name example \
	--zip-file fileb://main.zip
}

function cleanUp() {
	rm main.zip main
}

changeDir
build
zipBinary
upload
cleanUp
