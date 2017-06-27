package auth

import (
	"fmt"
	"net/url"

	"koding/klientctl/commands/cli"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/auth"

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
		kodingURL, err := url.Parse(opts.baseURL)
		if err != nil {
			return fmt.Errorf("%q is not a valid URL value: %s", opts.baseURL, err)
		}

		f, err := auth.NewFacade(&auth.FacadeOptions{
			Base: kodingURL,
			Log:  c.Log(),
		})
		if err != nil {
			return err
		}

		ctlcli.CloseOnExit(f)

		fmt.Fprintln(c.Err(), "Logging to", kodingURL, "...")

		loginOpts := &auth.LoginOptions{
			Team:  opts.team,
			Token: opts.token,
			Force: opts.force,
		}

		resp, err := f.Login(loginOpts)
		if err != nil {
			return fmt.Errorf("error logging into your Koding account: %v", err)
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), resp)
			return nil
		}

		if resp.GroupName != "" {
			fmt.Fprintln(c.Out(), "Successfully logged in to the following team:", resp.GroupName)
		} else {
			fmt.Fprintf(c.Out(), "Successfully authenticated to Koding.\n\nPlease run \"kd auth login "+
				"[--team myteam]\" in order to login to your team.\n")
		}

		fmt.Fprintf(c.Out(), "\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n")

		return nil
	}
}
