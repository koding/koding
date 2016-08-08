package main

import (
	artifactory "artifactory.v401"
	"fmt"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"os"
)

var (
	username = kingpin.Arg("username", "Username to delete").Required().String()
)

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()
	err := client.DeleteUser(*username)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		fmt.Printf("User %s deleted\n", *username)
		os.Exit(0)
	}
}
