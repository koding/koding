package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"os"

	artifactory "artifactory.v401"
)

var (
	username  = kingpin.Arg("username", "username to create").Required().String()
	email     = kingpin.Flag("email", "email address for new user").Required().String()
	showpass  = kingpin.Flag("showpass", "show randomly generated password for new user").Default("false").Bool()
	updatable = kingpin.Flag("updatable", "can user update profile?").Bool()
	group     = kingpin.Flag("group", "optional group for user. specify multiple times for multiple groups").Strings()
)

func randPass() string {
	b := make([]byte, 16)
	rand.Read(b)
	encode := base64.StdEncoding
	d := make([]byte, encode.EncodedLen(len(b)))
	encode.Encode(d, b)
	return string(d)
}

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()

	password := randPass()

	var details artifactory.UserDetails = artifactory.UserDetails{
		Email:    *email,
		Password: password,
	}
	if group != nil {
		details.Groups = *group
	}

	if updatable != nil {
		details.ProfileUpdatable = *updatable
	}
	err := client.CreateUser(*username, details)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		if *showpass {
			fmt.Printf("User created. Random password is: %s\n", password)
		}
		os.Exit(0)
	}
}
