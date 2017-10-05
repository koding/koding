package daemon

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/config"
	"koding/klientctl/daemon"

	"github.com/spf13/cobra"
)

type installOptions struct {
	prefix  string
	baseURL string
	token   string
	team    string
	skip    []string
	force   bool
}

// NewInstallCommand creates a command that is used to install the deamon and
// other KD dependencies.
func NewInstallCommand(c *cli.CLI) *cobra.Command {
	opts := &installOptions{}

	cmd := &cobra.Command{
		Use:   "install",
		Short: "Install the deamon and reqired dependencies",
		RunE:  installCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.prefix, "prefix", "", "overwrite installation directory")
	flags.StringVar(&opts.baseURL, "baseurl", config.Konfig.Endpoints.Koding.Public.String(), "service login endpoint")
	flags.StringVar(&opts.token, "token", "", "temporary authorization token")
	flags.StringVar(&opts.team, "team", "", "team to login")
	flags.StringSliceVar(&opts.skip, "skip", nil, "steps to skip during installation")
	flags.BoolVarP(&opts.force, "force", "f", false, "execute all install steps")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.AdminRequired, // Root privileges are required.
		cli.NoArgs,        // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func installCommand(c *cli.CLI, opts *installOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		daemonOpts := &daemon.Opts{
			Force:   opts.force,
			Prefix:  opts.prefix,
			Baseurl: opts.baseURL,
			Token:   opts.token,
			Team:    opts.team,
			Skip:    opts.skip,
		}

		return daemon.Install(daemonOpts)
	}
}
