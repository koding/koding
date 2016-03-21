// +build darwin
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
	// mountname on /mountfolder (osxfusefs, nodev, nosuid, synchronous, mounted by senthil)
	FuseTag = "osxfusefs"

	FuseMatcher = regexp.MustCompile(fmt.Sprintf("^(.*?) on (.*?) \\(%s,", FuseTag))
)
