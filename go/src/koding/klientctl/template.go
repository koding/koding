package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"text/tabwriter"

	"koding/klientctl/endpoint/remoteapi"
	"koding/remoteapi/models"

	"github.com/codegangsta/cli"
	"github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl/printer"
	"github.com/koding/logging"
	yaml "gopkg.in/yaml.v2"
)

// TODO(rjeczalik): set active team basing on a slug - after #10269

func TemplateList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	tf := &remoteapi.TemplateFilter{
		Provider: c.String("provider"),
	}

	if c.NArg() == 1 {
		tf.Slug = c.Args().Get(0)
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
		ID: c.String("id"),
	}

	if c.NArg() == 1 {
		tf.Slug = c.Args().Get(0)
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
		ID: c.String("id"),
	}

	if c.NArg() == 1 {
		tf.Slug = c.Args().Get(0)
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

	if err := remoteapi.DeleteTemplate(tf.ID); err != nil {
		return 1, err
	}

	fmt.Printf("Stack template with %q ID deleted successfully.\n", tf.ID)

	return 0, nil
}

func printTemplates(templates []*models.JStackTemplate) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Println(w, "TITLE\tDESCRIPTION\tTEAM\tMACHINES")

	for _, tmpl := range templates {
		fmt.Fprintf(w, "%s\t%s\t%v\t%d\n", tmpl.Title, tmpl.Description, tmpl.Group, len(tmpl.Machines))
	}
}
