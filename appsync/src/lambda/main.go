package main

import (
	"context"
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

func main() {
	lambda.Start(handler)
}

func handler(ctx context.Context, payload map[string]any) error {
	fmt.Printf("%#v", payload)
	return nil
}
