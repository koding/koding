package main

import (
	"fmt"
	"time"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func CredentialImport(c *cli.Context, log logging.Logger, _ string) (int, error) {
	kloud, err := Kloud()
	if err != nil {
		return 1, err
	}

	resp, err := kloud.TellWithTimeout("credential.list", 10*time.Second)
	if err != nil {
		return 1, err
	}

	fmt.Println(string(resp.Raw))

	return 1, err
}

func CredentialList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	return 0, nil
}

func CredentialCreate(c *cli.Context, log logging.Logger, _ string) (int, error) {
	return 0, nil
}
