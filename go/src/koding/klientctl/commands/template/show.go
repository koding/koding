package template

import (
	"encoding/json"
	"errors"
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/remoteapi"

	"github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl/printer"
	"github.com/spf13/cobra"
	yaml "gopkg.in/yaml.v2"
)

type showOptions struct {
	id         string
	hclOutput  bool
	jsonOutput bool
}

// NewShowCommand creates a command that shows details of a given stack template.
func NewShowCommand(c *cli.CLI) *cobra.Command {
	opts := &showOptions{}

	cmd := &cobra.Command{
		Use:   "show [<template-slug>]",
		Short: "Show stack template details",
		RunE:  showCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.id, "id", "", "limit to template id")
	flags.BoolVar(&opts.hclOutput, "hcl", false, "output in HCL format")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.MaxArgs(1),     // No more than 1 arg.
	)(c, cmd)

	return cmd
}

func showCommand(c *cli.CLI, opts *showOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		f := &remoteapi.Filter{
			ID: opts.id,
		}

		if len(args) > 0 {
			f.Slug = args[0]
		}

		if f.ID == "" && f.Slug == "" {
			return errors.New("error requesting template - missing slug name")
		}

		tmpls, err := remoteapi.ListTemplates(f)
		if err != nil {
			return err
		}

		if len(tmpls) != 1 {
			return fmt.Errorf("error requesting template - got %d templates, expecting only one", len(tmpls))
		}

		tmpl := tmpls[0]

		var v interface{}
		if err := json.Unmarshal([]byte(tmpl.Template.Content), &v); err != nil {
			return errors.New("error reading template: " + err.Error())
		}

		switch {
		case opts.jsonOutput:
			cli.PrintJSON(c.Out(), v)
		case opts.hclOutput:
			tree, err := hcl.Parse(tmpl.Template.Content)
			if err != nil {
				return errors.New("error reading template: " + err.Error())
			}

			printer.Fprint(c.Out(), tree)
			fmt.Fprintln(c.Out())
		default:
			p, err := yaml.Marshal(v)
			if err != nil {
				return errors.New("error reading template: " + err.Error())
			}

			fmt.Fprintf(c.Out(), "%s\n", p)
		}

		return nil
	}
}
