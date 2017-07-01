package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"text/tabwriter"

	"koding/klientctl/app"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/helper"
	"koding/remoteapi/models"

	"github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl/printer"
	"github.com/koding/logging"
	cli "gopkg.in/urfave/cli.v1"
	yaml "gopkg.in/yaml.v2"
)

func TemplateList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	f := &remoteapi.Filter{
		Slug: c.String("template"),
		Team: c.String("team"),
	}

	if f.Slug == "" {
		f.Slug = kloud.Username() + "/"
	}

	tmpls, err := remoteapi.ListTemplates(f)
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
	f := &remoteapi.Filter{
		ID:   c.String("id"),
		Slug: c.Args().Get(0),
	}

	if f.ID == "" && f.Slug == "" {
		return 1, errors.New("error requesting template - missing slug name")
	}

	tmpls, err := remoteapi.ListTemplates(f)
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
	f := &remoteapi.Filter{
		ID:   c.String("id"),
		Slug: c.String("template"),
	}

	if f.ID == "" && f.Slug == "" {
		return 1, errors.New("error deleting template - missing slug name")
	}

	if f.ID == "" {
		tmpls, err := remoteapi.ListTemplates(f)
		if err != nil {
			return 1, err
		}

		if len(tmpls) != 1 {
			return 1, fmt.Errorf("error deleting template - got %d templates, expecting only one", len(tmpls))
		}

		f.ID = tmpls[0].ID
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

	if err := remoteapi.DeleteTemplate(f.ID); err != nil {
		return 1, err
	}

	fmt.Printf("Stack template with %q ID deleted successfully.\n", f.ID)

	return 0, nil
}

func templateInit(output string, useDefaults bool, providerName string) (map[string]string, error) {
	if _, err := os.Stat(output); err == nil && !useDefaults {
		yn, err := helper.Ask("Do you want to overwrite %q file? [y/N]: ", output)
		if err != nil {
			return nil, err
		}

		switch strings.ToLower(yn) {
		case "yes", "y":
			fmt.Println()
		default:
			return nil, errors.New("aborted by user")
		}
	}

	if providerName == "" {
		var err error
		if providerName, err = helper.Ask("Provider type []: "); err != nil {
			return nil, err
		}
	}

	opts := &app.TemplateOptions{
		Provider: providerName,
	}

	v, vars, err := app.BuildTemplate(opts)
	if err != nil {
		return nil, err
	}

	p, err := yaml.Marshal(v)
	if err != nil {
		return nil, err
	}

	f, err := os.Create(output)
	if err != nil {
		return nil, err
	}

	_, err = io.Copy(f, bytes.NewReader(p))
	err = nonil(err, f.Close())

	if err != nil {
		return nil, err
	}

	fmt.Printf("\nTemplate successfully written to %s.\n", f.Name())

	return vars, nil
}

func TemplateInit(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if _, err := templateInit(c.String("output"), c.Bool("defaults"), c.String("provider")); err != nil {
		return 1, err
	}

	return 0, nil
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

func printTemplates(templates []*models.JStackTemplate) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tTITLE\tSLUG\tOWNER\tTEAM\tACCESS\tMACHINES")

	for _, tmpl := range templates {
		owner := *tmpl.OriginID
		if owner != "" {
			if account, err := remoteapi.Account(&models.JAccount{ID: owner}); err == nil {
				owner = account.Profile.Nickname
			}
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t%d\n", tmpl.ID, str(tmpl.Title), str(tmpl.Slug), owner, str(tmpl.Group), tmpl.AccessLevel, len(tmpl.Machines))
	}
}

func str(s *string) string {
	if s == nil || *s == "" {
		return "-"
	}
	return *s
}
