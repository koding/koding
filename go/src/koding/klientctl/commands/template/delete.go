package template

import (
	"errors"
	"fmt"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/helper"

	"github.com/spf13/cobra"
)

type deleteOptions struct {
	template string
	id       string
	force    bool
}

// NewDeleteCommand creates a command that is used to delete stack templates.
func NewDeleteCommand(c *cli.CLI) *cobra.Command {
	opts := &deleteOptions{}

	cmd := &cobra.Command{
		Use:   "delete",
		Short: "Delete a stack template",
		RunE:  deleteCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.template, "template", "t", "", "limit to template name")
	flags.StringVar(&opts.id, "id", "", "limit to template id")
	flags.BoolVar(&opts.force, "force", false, "confirm all questions")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func deleteCommand(c *cli.CLI, opts *deleteOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		f := &remoteapi.Filter{
			ID:   opts.id,
			Slug: opts.template,
		}

		if f.ID == "" && f.Slug == "" {
			return errors.New("error deleting template - missing slug name")
		}

		if f.ID == "" {
			tmpls, err := remoteapi.ListTemplates(f)
			if err != nil {
				return err
			}

			if len(tmpls) != 1 {
				return fmt.Errorf("error deleting template - got %d templates, expecting only one", len(tmpls))
			}

			f.ID = tmpls[0].ID
		}

		if !opts.force {
			s, err := helper.Fask(c.In(), c.Out(), `Please type "yes" to confirm you want to delete the resource []: `)
			if err != nil {
				return err
			}

			if s != "yes" {
				return errors.New("confirmation failed, aborting")
			}
		}

		if err := remoteapi.DeleteTemplate(f.ID); err != nil {
			return err
		}

		fmt.Fprintf(c.Out(), "Stack template with %q ID deleted successfully.\n", f.ID)

		return nil
	}
}
