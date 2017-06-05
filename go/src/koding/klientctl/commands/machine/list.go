package machine

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/config"

	"github.com/spf13/cobra"
)

type listOptions struct {
	jsonOutput bool
}
