package auth

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type registerOptions struct {
	username      string
	firstName     string
	lastName      string
	password      string
	email         string
	team          string
	company       string
	newsletter    bool
	alreadyMember bool
}

// NewRegisterCommand creates a command that displays remote machines which belong
// to the user or that can be accessed by their.
func NewRegisterCommand(c *cli.CLI) *cobra.Command {
	opts := &registerOptions{}

	cmd := &cobra.Command{
		Use:   "register",
		Short: "Register the user",
		RunE:  registerCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.username, "username", "u", "", "account username")
	flags.StringVar(&opts.firstName, "firstName", "", "user first name")
	flags.StringVar(&opts.lastName, "lastName", "", "user last name")
	flags.StringVarP(&opts.password, "password", "p", "", "account password")
	flags.StringVar(&opts.email, "email", "", "email address")
	flags.StringVar(&opts.team, "team", "", "team name")
	flags.StringVar(&opts.company, "company", "", "company name, defaults to team name")
	flags.BoolVar(&opts.newsletter, "newsletter", false, "subscription to newsletters")
	flags.BoolVar(&opts.alreadyMember, "alreadyMember", false, "already registered member")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func registerCommand(c *cli.CLI, opts *registerOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
