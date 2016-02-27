package main

import (
	"koding/fusetest"
	"log"
	"os"
	"testing"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Pass mounted path as argument to run tests.")
	}

	fusetest.RunAllTests(&testing.T{}, os.Args[1])
}
