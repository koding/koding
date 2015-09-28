package main

import (
	"bytes"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func init() {
	rand.Seed(time.Now().Unix())
}

var (
	// Version is the current version of kd. This number needs to be updated
	// when we release a new version.
	version = 1

	// S3UpdateLocation is publically accessible url to check for new updates.
	S3UpdateLocation = "https://koding-kd.s3.amazonaws.com/latest-version.txt"
)

type CheckUpdate struct {
	Location           string
	RandomSeededNumber int
}

// NewCheckUpdate is the required initializer for CheckUpdate.
func NewCheckUpdate() *CheckUpdate {
	return &CheckUpdate{
		Location:           S3UpdateLocation,
		RandomSeededNumber: rand.Intn(3),
	}
}

// IsUpdateAvailable checks if a newer version of `kd` is available for
// download by hitting an S3 file and comparing the number in that file
// to local version number. It only checks 1 out of 3 times randomly to
// avoid checking for update each time.
func (c *CheckUpdate) IsUpdateAvailable() (bool, error) {
	if c.RandomSeededNumber != 1 {
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

	return newVersion > version, nil
}
