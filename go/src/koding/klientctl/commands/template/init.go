package template

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"

	"koding/kites/kloud/stack/provider"
	"koding/klientctl/commands/cli"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/helper"

	"github.com/spf13/cobra"
	yaml "gopkg.in/yaml.v2"
)

type initOptions struct {
	output   string
	provider string
	defaults bool
}

// NewInitCommand creates a command that generates a new stack template.
func NewInitCommand(c *cli.CLI) *cobra.Command {
	opts := &initOptions{}

	cmd := &cobra.Command{
		Use:   "init",
		Short: "Generate a new stack template file",
		RunE:  initCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.output, "output", "o", config.Konfig.Template.File, "output filename")
	flags.StringVarP(&opts.provider, "provider", "p", "", "cloud provider to use")
	flags.BoolVar(&opts.defaults, "defaults", false, "use default values for stack vars")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func initCommand(c *cli.CLI, opts *initOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return Init(c, opts.output, opts.defaults, opts.provider)
	}
}

// Init initializes a template.
func Init(c *cli.CLI, output string, useDefaults bool, providerName string) error {
	if _, err := os.Stat(output); err == nil && !useDefaults {
		yn, err := helper.Fask(c.In(), c.Out(), "Do you want to overwrite %q file? [y/N]: ", output)
		if err != nil {
			return err
		}

		switch strings.ToLower(yn) {
		case "yes", "y":
			fmt.Fprintln(c.Out())
		default:
			return errors.New("aborted by user")
		}
	}

	descs, err := credential.Describe()
	if err != nil {
		return err
	}

	if providerName == "" {
		if providerName, err = helper.Fask(c.In(), c.Out(), "Provider type []: "); err != nil {
			return err
		}
	}

	if _, ok := descs[providerName]; !ok {
		return fmt.Errorf("provider %q does not exist", providerName)
	}

	tmpl, defaults, err := remoteapi.SampleTemplate(providerName)
	if err != nil {
		return err
	}

	vars := provider.ReadVariables(tmpl)
	input := make(map[string]string)

	for _, v := range vars {
		if !strings.HasPrefix(v.Name, "userInput_") {
			continue
		}

		name := v.Name[len("userInput_"):]
		defValue := ""
		if v, ok := defaults[name]; ok && v != nil {
			defValue = fmt.Sprintf("%v", v)
		}

		var value string

		if !useDefaults {
			if value, err = helper.Fask(c.In(), c.Out(), "Set %q to [%s]: ", name, defValue); err != nil {
				return err
			}
		}

		if value == "" {
			value = defValue
		}

		input[v.Name] = value
	}

	tmpl = provider.ReplaceVariablesFunc(tmpl, vars, func(v *provider.Variable) string {
		if s, ok := input[v.Name]; ok {
			return s
		}

		return v.String()
	})

	var m map[string]interface{}

	if err := json.Unmarshal([]byte(tmpl), &m); err != nil {
		return err
	}

	p, err := yaml.Marshal(m)
	if err != nil {
		return err
	}

	f, err := os.Create(output)
	if err != nil {
		return err
	}

	_, err = io.Copy(f, bytes.NewReader(p))
	err = nonil(err, f.Close())

	if err != nil {
		return err
	}

	fmt.Fprintf(c.Out(), "\nTemplate successfully written to %s.\n", f.Name())

	return nil
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
