// +build linux
package mountcli

import (
	"fmt"
	"regexp"
)

var (
	// An OS specific mount tag that we're filtering by.
	//
	// Example:
	//
	// mountname on /mountfolder type fuse (rw,nosuid,nodev,allow_other)
	FuseTag = "fuse"

	FuseMatcher = regexp.MustCompile(fmt.Sprintf("^(.*?) on (.*?) type %s ", FuseTag))
)
