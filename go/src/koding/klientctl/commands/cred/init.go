package cred

import (
	"bytes"
	"fmt"
	"io"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/credential"
	"os"

	"github.com/spf13/cobra"
)

type initOptions struct {
	provider string
	output   string
	title    string
}

// NewInitCommand creates a command that creates a credential file.
func NewInitCommand(c *cli.CLI) *cobra.Command {
	opts := &initOptions{}

	cmd := &cobra.Command{
		Use:   "init",
		Short: "Create a credential file",
		RunE:  initCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "credential provider")
	flags.StringVarP(&opts.output, "output", "o", "credential.json", "output filename")
	flags.StringVar(&opts.title, "title", "", "credential title")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func initCommand(c *cli.CLI, opts *initOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		createOpts := &credential.CreateOptions{
			Provider: opts.provider,
			Title:    opts.title,
		}

		createOpts, err := askCredentialCreate(c, createOpts)
		if err != nil {
			return err
		}

		f, err := os.Create(opts.output)
		if err != nil {
			return err
		}

		_, err = io.Copy(f, bytes.NewReader(createOpts.Data))
		if err = nonil(err, f.Close()); err != nil {
			return err
		}

		fmt.Fprintf(c.Err(), "Credentials successfully written to %s.\n", opts.output)

		return nil
	}
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
