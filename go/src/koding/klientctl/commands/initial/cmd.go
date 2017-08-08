package initial

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	kstack "koding/kites/kloud/stack"
	"koding/kites/kloud/utils/object"
	"koding/klientctl/commands/cli"
	"koding/klientctl/commands/cred"
	"koding/klientctl/commands/template"
	"koding/klientctl/config"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/stack"
	"koding/klientctl/endpoint/team"
	"koding/klientctl/helper"

	"github.com/spf13/cobra"
	yaml "gopkg.in/yaml.v2"
)

type options struct{}

// NewCommand creates a command that initializes new KD project.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "init",
		Short: "Initialize a new project",
		RunE:  command(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		if err := isLocked(); err != nil {
			return err
		}

		if _, err := os.Stat(config.Konfig.Template.File); os.IsNotExist(err) {
			fmt.Fprintf(c.Out(), "Initializing with new %s template file...\n\n", config.Konfig.Template.File)

			if err := template.Init(c, config.Konfig.Template.File, false, ""); err != nil {
				return err
			}
		}

		p, err := readTemplate(config.Konfig.Template.File)
		if err != nil {
			return err
		}

		provider, err := kstack.ReadProvider(p)
		if err != nil {
			return errors.New("failed to read cloud provider: " + err.Error())
		}

		ident := credential.Used()[provider]

		switch {
		case ident == "":
			opts := &credential.ListOptions{
				Provider: provider,
				Team:     team.Used().Name,
			}
			cs, err := credential.List(opts)
			if err != nil {
				c.Log().Debug("credential.List failure: %s", err)
				break
			}

			creds, ok := cs[provider]
			if !ok || len(creds) == 0 {
				fmt.Fprintf(c.Out(), "Creating new credential for %q provider...\n\n", strings.Title(provider))

				opts := &credential.CreateOptions{
					Provider: provider,
					Team:     team.Used().Name,
				}

				if err := cred.Create(c, "", opts, false); err != nil {
					return err
				}

				break
			}

			for i, cred := range creds {
				fmt.Fprintf(c.Out(), "[%d] %s\n", i+1, cred.Title)
			}

			s, err := helper.Fask(c.In(), c.Out(), "\nChoose credential to use [1]: ")
			if err != nil {
				return err
			}

			if s == "" {
				s = "1"
			}

			n, err := strconv.Atoi(s)
			if err != nil {
				return fmt.Errorf("unrecognized credential chosen: %s", s)
			}

			if n--; n < 0 || n >= len(creds) {
				return fmt.Errorf("invalid credential chosen: %d", n)
			}

			ident = creds[n].Identifier
			credential.Use(ident)
		}

		if ident == "" {
			ident = credential.Used()[provider]
		}

		fmt.Fprintf(c.Out(), "Creating new stack...\n\n")
		defTitle := strings.Title(fmt.Sprintf("%s %s Stack", kstack.Pokemon(), provider))

		title, err := helper.Fask(c.In(), c.Out(), "Stack name [%s]: ", defTitle)
		if err != nil {
			return err
		}

		if title == "" {
			title = defTitle
		}

		opts := &stack.CreateOptions{
			Team:        team.Used().Name,
			Title:       title,
			Credentials: []string{ident},
			Template:    p,
		}

		resp, err := stack.Create(opts)
		if err != nil {
			return err
		}

		fmt.Fprintf(c.Err(), "\nCreatad %q stack with %s ID.\nWaiting for the stack to finish building...\n\n", resp.Title, resp.StackID)

		for e := range kloud.Wait(resp.EventID) {
			if e.Error != nil {
				return fmt.Errorf("building %q stack failed: %s", resp.Title, e.Error)
			}

			fmt.Fprintf(c.Out(), "[%d%%] %s\n", e.Event.Percentage, e.Event.Message)
		}

		if err := writelock(resp.StackID, resp.Title); err != nil {
			return err
		}

		return nil
	}
}

type lock struct {
	Stack struct {
		ID    string `yaml:"id"`
		Title string `yaml:"title"`
	} `yaml:"stack"`
}

func isLocked() error {
	p, err := ioutil.ReadFile(".kd.lock")
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return err
	}

	var l lock

	if err := yaml.Unmarshal(p, &l); err != nil {
		return err
	}

	return fmt.Errorf("project already initialized with %q stack (%s)", l.Stack.Title, l.Stack.ID)
}

func writelock(id, title string) error {
	var l lock
	l.Stack.ID = id
	l.Stack.Title = title

	p, err := yaml.Marshal(&l)
	if err != nil {
		return err
	}

	return ioutil.WriteFile(".kd.lock", p, 0644)
}

func readTemplate(file string) ([]byte, error) {
	p, err := ioutil.ReadFile(file)
	if err != nil {
		return nil, err
	}

	var m map[string]interface{}

	if err := yaml.Unmarshal(p, &m); err != nil {
		return nil, err
	}

	return json.Marshal(object.FixYAML(m))
}
