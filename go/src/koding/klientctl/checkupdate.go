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

// CheckUpdateFirst can be prepended to any existing cli command to have it
// check if there's an update available before running the command.
func CheckUpdateFirst(f ExitingCommand) ExitingCommand {
	return func(c *cli.Context) int {
		u := NewCheckUpdate()
		if y, err := u.IsUpdateAvailable(); y && err == nil {
			fmt.Printf("A newer version of %s is available. Please do `sudo %s update`.\n", Name, Name)
		}

		return f(c)
	}
}

// CheckUpdate checks if there an update available.
type CheckUpdate struct {
	// Location is the url we check if there's a new update available. If the
	// number in this location is greater than the number hardcoded in this
	// binary it return true.
	Location string

	// RandomSeededNumber is a random number so we don't check update each time.
	RandomSeededNumber int

	// ForceCheck forces checking of update regardless of the value of above
	// random number.
	ForceCheck bool

	// LocalVersion is the version which CheckUpdate will compare against.
	// Typically, the binary version itself.
	LocalVersion int
}

// NewCheckUpdate is the required initializer for CheckUpdate.
func NewCheckUpdate() *CheckUpdate {
	return &CheckUpdate{
		LocalVersion:       Version,
		Location:           S3UpdateLocation,
		RandomSeededNumber: rand.Intn(3),
		ForceCheck:         false,
	}
}

// IsUpdateAvailable checks if a newer version of `kd` is available.
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

	return newVersion > c.LocalVersion, nil
}
