package main

import (
	"fmt"
	"os"

	artifactory "artifactory.v401"
)

func main() {
	client := artifactory.NewClientFromEnv()
	p, err := client.GetGeneralConfiguration()
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		fmt.Printf("%s\n", p)
		os.Exit(0)
	}
}
