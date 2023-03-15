package main

import (
	"log"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatal("parameter is required")
	}
	os.Stdout.WriteString(os.Args[1])
}
