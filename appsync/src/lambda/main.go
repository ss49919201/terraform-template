package main

import (
	"context"
	"errors"

	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(handler)
}

type payload struct {
	Data int
}

func handler(ctx context.Context, p *payload) (*int, error) {
	if p.Data == 0 {
		return nil, errors.New("data is invalid")
	}
	return &p.Data, nil
}
