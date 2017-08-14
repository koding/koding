package cli

import (
	"fmt"

	"koding/klientctl/config"

	"github.com/spf13/cobra"
)

const cacheLockedSuggestion = `
It seems that another kd process is currently running and doing write operations
that prevented this one from starting up.

Usually, it is enough to retry. If that happens again, please verify that you
have no hanging kd processes. Alternatively, if you execute a number of kd
processes concurrently and a number of them fail, you may want to increase
database lock timeout with:

   kd config set lockTimeout 10`

// WithInitializedCache ensures that config cache is accessible and attached to
// config default cache client.
func WithInitializedCache(cli *CLI, rootCmd *cobra.Command) {
	cli.registerMiddleware("initialized_cache", rootCmd)
	tail := rootCmd.RunE
	if tail == nil {
		panic("cannot insert middleware into empty function")
	}

	rootCmd.RunE = func(cmd *cobra.Command, args []string) error {
		cache, err := config.Open()
		if err != nil {
			cli.Log().Error("Cannot open config cache: %v", err)

			return NewError(3, fmt.Errorf(
				"Error opening configuration cache: %s\n\n%s", err, cacheLockedSuggestion,
			))
		}
		defer cache.Close()

		config.DefaultCache = cache

		return tail(cmd, args)
	}
}
