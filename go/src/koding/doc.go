package koding

// Packages built by build.sh script.
import (
	_ "github.com/koding/kite/kitectl"
	_ "github.com/canthefason/go-watcher"
	_ "github.com/mattes/migrate"
	_ "github.com/alecthomas/gocyclo"
	_ "github.com/remyoudompheng/go-misc/deadcode"
	_ "github.com/opennota/check/cmd/varcheck"
	_ "github.com/barakmich/go-nyet"
	_ "github.com/jteeuwen/go-bindata/go-bindata"
	_ "github.com/koding/terraform-provider-github/cmd/provider-github"
)
