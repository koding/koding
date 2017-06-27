package cred

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"strconv"
	"time"

	"koding/kites/config"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/spf13/cobra"
)

type createOptions struct {
	provider   string
	file       string
	team       string
	title      string
	jsonOutput bool
}

// NewCreateCommand creates a command that can be used to create new stack
// credential.
func NewCreateCommand(c *cli.CLI) *cobra.Command {
	opts := &createOptions{}

	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create a new stack credential",
		RunE:  createCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "credential provider")
	flags.StringVarP(&opts.file, "file", "f", "", "read from file")
	flags.StringVar(&opts.team, "team", "", "owner of the credential")
	flags.StringVar(&opts.title, "title", "", "credential title")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func createCommand(c *cli.CLI, opts *createOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		createOpts := &credential.CreateOptions{
			Provider: opts.provider,
			Team:     opts.team,
			Title:    opts.title,
		}

		if err := Create(c, opts.file, createOpts, opts.jsonOutput); err != nil {
			return err
		}

		return nil
	}
}

// Create creates new credentials.
func Create(c *cli.CLI, file string, opts *credential.CreateOptions, js bool) error {
	var p []byte
	var err error

	switch file {
	case "":
		opts, err = askCredentialCreate(c, opts)
		if err != nil {
			return fmt.Errorf("error building credential data: %v", err)
		}
	case "-":
		p, err = ioutil.ReadAll(c.In())
	default:
		p, err = ioutil.ReadFile(file)
	}

	if err != nil {
		return fmt.Errorf("error reading credential file: %v", err)
	}

	fmt.Fprintln(c.Err(), "Creating credential... ")

	if len(opts.Data) == 0 {
		opts.Data = p
	}

	cred, err := credential.Create(opts)
	if err != nil {
		return fmt.Errorf("error creating credential: %v", err)
	}

	if js {
		cli.PrintJSON(c.Out(), cred)
		return nil
	}

	fmt.Fprintf(c.Err(), "Created %q credential with %s identifier.\n", cred.Title, cred.Identifier)

	return nil
}

func askCredentialCreate(c *cli.CLI, opts *credential.CreateOptions) (*credential.CreateOptions, error) {
	descs, err := credential.Describe()
	if err != nil {
		return nil, err
	}

	if opts.Provider == "" {
		opts.Provider, err = helper.Fask(c.In(), c.Out(), "Provider type []: ")
		if err != nil {
			return nil, err
		}
	}

	if opts.Title == "" {
		opts.Title = config.CurrentUser.Username + " " + time.Now().Format(time.ANSIC)
		opts.Title, err = helper.Fask(c.In(), c.Out(), "Title [%s]: ", opts.Title)
		if err != nil {
			return nil, err
		}
	}

	desc, ok := descs[opts.Provider]
	if !ok {
		return nil, fmt.Errorf("provider %q does not exist", opts.Provider)
	}

	creds := make(map[string]interface{}, len(desc.Credential))

	// TODO(rjeczalik): Add field.OmitEmpty so we validate required
	// fields client-side.
	//
	// TODO(rjeczalik): Refactor part which validates credential
	// input on kloud/provider side to a separate library
	// and use it here.
	for _, field := range desc.Credential {
		var value string

		if field.Secret {
			value, err = helper.FaskSecret(c.In(), c.Out(), "%s [***]: ", field.Label)
		} else {
			var defaultValue string

			switch {
			case len(field.Values) > 0:
				if s, ok := field.Values[0].Value.(string); ok {
					defaultValue = s
				}
			case field.Type == "duration":
				defaultValue = "0s"
			case field.Type == "integer":
				defaultValue = "0"
			}

			value, err = helper.Fask(c.In(), c.Out(), "%s [%s]: ", field.Label, defaultValue)

			if value == "" {
				value = defaultValue
			}
		}

		if err != nil {
			return nil, err
		}

		switch field.Type {
		case "integer":
			n, err := strconv.Atoi(value)
			if err != nil {
				return nil, fmt.Errorf("invalid integer for %q field: %s", field.Label, err)
			}

			creds[field.Name] = n
		case "duration":
			d, err := time.ParseDuration(value)
			if err != nil {
				return nil, fmt.Errorf("invalid time duration for %q field: %s", field.Label, err)
			}

			creds[field.Name] = d
		case "enum":
			if !field.Values.Contains(value) {
				return nil, fmt.Errorf("invalid %q enumeration value for %q field - valid values are: %v", value, field.Label, field.Values.Values())
			}

			creds[field.Name] = value
		default:
			creds[field.Name] = value
		}
	}

	// TODO(rjeczalik): remove when support for generic team is implemented
	if opts.Team == "" {
		opts.Team, err = helper.Fask(c.In(), c.Out(), "Team name [%s]: ", team.Used().Name)
		if err != nil {
			return nil, err
		}

		if opts.Team == "" {
			opts.Team = team.Used().Name
		}
	}

	p, err := json.Marshal(creds)
	if err != nil {
		return nil, err
	}

	opts.Data = p

	return opts, nil
}
