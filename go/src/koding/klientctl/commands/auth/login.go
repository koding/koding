package auth

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/config"

	"github.com/spf13/cobra"
)

type loginOptions struct {
	token      string
	baseURL    string
	team       string
	jsonOutput bool
	force      bool
}

// NewLoginCommand creates a command that allows to log into Koding account.
func NewLoginCommand(c *cli.CLI) *cobra.Command {
	opts := &loginOptions{}

	cmd := &cobra.Command{
		Use:   "login",
		Short: "Log into kd.io or koding.com account",
		RunE:  loginCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.token, "token", "", "temporary authorization token")
	flags.StringVar(&opts.baseURL, "baseurl", config.Konfig.Endpoints.Koding.Public.String(), "service login endpoint")
	flags.StringVar(&opts.team, "team", "kd.io", "team to login")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")
	flags.BoolVarP(&opts.force, "force", "f", false, "force new session")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func loginCommand(c *cli.CLI, opts *loginOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
