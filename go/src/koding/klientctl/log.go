package main

import (
	"errors"
	"fmt"

	"koding/klientctl/endpoint/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func LogUpload(c *cli.Context, log logging.Logger, _ string) (int, error) {
	f := []*machine.UploadedFile{{
		File: c.Args().Get(0),
	}}

	if f[0].File == "" {
		return 1, errors.New("file path is empty or missing")
	}

	if err := machine.Upload(f); err != nil {
		return 1, err
	}

	fmt.Println(f[0].URL)

	return 0, nil
}
