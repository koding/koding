package api

import (
	"testing"

	"github.com/koding/logging"
)

// Log is a logger for use in tests.
var Log = logging.NewCustom("api", testing.Verbose())
