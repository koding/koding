package main

import (
	"koding/fusetest"
	"log"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Pass machine name as arguments to run tests.")
	}

	f, err := fusetest.NewFusetest(os.Args[1])
	if err != nil {
		log.Fatal(err)
	}

	f.RunAllTests()
}
