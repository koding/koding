package main

import (
	"bytes"
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/codegangsta/cli"
)

func init() {
	rand.Seed(time.Now().Unix())
}

func CheckUpdateFirst(f ExitingCommand) ExitingCommand {
	return func(c *cli.Context) int {
		u := NewCheckUpdate()
		if y, err := u.IsUpdateAvailable(); y && err == nil {
			fmt.Println("A newer version of %s is available. Please do `sudo kd update`.\n", Name)
		}

		return f(c)
	}
}

// CheckUpdate checks if there an update available based on checking.
type CheckUpdate struct {
	Location           string
	RandomSeededNumber int
	ForceCheck         bool
}

// NewCheckUpdate is the required initializer for CheckUpdate.
func NewCheckUpdate() *CheckUpdate {
	return &CheckUpdate{
		Location:           S3UpdateLocation,
		RandomSeededNumber: rand.Intn(3),
		ForceCheck:         false,
	}
}

// IsUpdateAvailable checks if a newer version of `kd` is available for
// download by hitting an S3 file and comparing the number in that file
// to local version number. It only checks 1 out of 3 times randomly to
// avoid checking for update each time.
func (c *CheckUpdate) IsUpdateAvailable() (bool, error) {
	if !c.ForceCheck && c.RandomSeededNumber != 1 {
		return false, nil
	}

	resp, err := http.Get(c.Location)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	buf := new(bytes.Buffer)
	if _, err := buf.ReadFrom(resp.Body); err != nil {
		return false, err
	}

	// remove any newlines at EOF.
	str := strings.TrimSuffix(buf.String(), "\n")
	newVersion, err := strconv.Atoi(str)
	if err != nil {
		return false, err
	}

	return newVersion > KlientctlVersion, nil
}
