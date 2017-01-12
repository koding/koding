package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"text/tabwriter"

	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/helper"
	"koding/remoteapi/models"

	"github.com/codegangsta/cli"
	"github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl/printer"
	"github.com/koding/logging"
	yaml "gopkg.in/yaml.v2"
)

func TemplateList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	tf := &remoteapi.TemplateFilter{
		Slug: c.String("template"),
	}

	if tf.Slug == "" {
		tf.Slug = kloud.Username() + "/"
	}

	tmpls, err := remoteapi.ListTemplates(tf)
	if err != nil {
		return 1, err
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetEscapeHTML(false)
		enc.SetIndent("", "\t")
		enc.Encode(tmpls)

		return 0, nil
	}

	printTemplates(tmpls)

	return 0, nil
}

func TemplateShow(c *cli.Context, log logging.Logger, _ string) (int, error) {
	tf := &remoteapi.TemplateFilter{
		ID:   c.String("id"),
		Slug: c.String("template"),
	}

	if tf.ID == "" && tf.Slug == "" {
		return 1, errors.New("error requesting template - missing slug name")
	}

	tmpls, err := remoteapi.ListTemplates(tf)
	if err != nil {
		return 1, err
	}

	if len(tmpls) != 1 {
		return 1, fmt.Errorf("error requesting template - got %d templates, expecting only one", len(tmpls))
	}

	tmpl := tmpls[0]

	var v interface{}

	if err := json.Unmarshal([]byte(tmpl.Template.Content), &v); err != nil {
		return 1, errors.New("error reading template: " + err.Error())
	}

	switch {
	case c.Bool("json"):
		enc := json.NewEncoder(os.Stdout)
		enc.SetEscapeHTML(false)
		enc.SetIndent("", "\t")
		enc.Encode(v)

	case c.Bool("hcl"):
		tree, err := hcl.Parse(tmpl.Template.Content)
		if err != nil {
			return 1, errors.New("error reading template: " + err.Error())
		}

		printer.Fprint(os.Stdout, tree)
		fmt.Println()
	default:
		p, err := yaml.Marshal(v)
		if err != nil {
			return 1, errors.New("error reading template: " + err.Error())
		}

		fmt.Printf("%s\n", p)
	}

	return 0, nil
}

func TemplateDelete(c *cli.Context, log logging.Logger, _ string) (int, error) {
	tf := &remoteapi.TemplateFilter{
		ID:   c.String("id"),
		Slug: c.String("template"),
	}

	if tf.ID == "" && tf.Slug == "" {
		return 1, errors.New("error deleting template - missing slug name")
	}

	if tf.ID == "" {
		tmpls, err := remoteapi.ListTemplates(tf)
		if err != nil {
			return 1, err
		}

		if len(tmpls) != 1 {
			return 1, fmt.Errorf("error deleting template - got %d templates, expecting only one", len(tmpls))
		}

		tf.ID = tmpls[0].ID
	}

	if !c.Bool("force") {
		s, err := helper.Ask(`Please type "yes" to confirm you want to delete the resource []: `)
		if err != nil {
			return 1, err
		}

		if s != "yes" {
			return 1, errors.New("confirmation failed, aborting")
		}
	}

	if err := remoteapi.DeleteTemplate(tf.ID); err != nil {
		return 1, err
	}

	fmt.Printf("Stack template with %q ID deleted successfully.\n", tf.ID)

	return 0, nil
}

func printTemplates(templates []*models.JStackTemplate) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tTITLE\tOWNER\tTEAM\tACCESS\tMACHINES")

	for _, tmpl := range templates {
		owner := *tmpl.OriginID
		if owner != "" {
			if account, err := remoteapi.Account(&models.JAccount{ID: owner}); err == nil {
				owner = account.Profile.Nickname
			}
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%d\n", tmpl.ID, *tmpl.Title, owner, *tmpl.Group, tmpl.AccessLevel, len(tmpl.Machines))
	}
}
