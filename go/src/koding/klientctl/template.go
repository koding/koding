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

	"koding/kites/kloud/stack/provider"
	"koding/klientctl/endpoint/credential"
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

func TemplateInit(c *cli.Context, log logging.Logger, _ string) (int, error) {
	descs, err := credential.Describe()
	if err != nil {
		return 1, err
	}

	name, err := helper.Ask("Provider type []: ")
	if err != nil {
		return 1, err
	}

	if _, ok := descs[name]; !ok {
		return 1, fmt.Errorf("provider %q does not exist", name)
	}

	tmpl, err := remoteapi.SampleTemplate(name)
	if err != nil {
		return 1, err
	}

	vars := provider.ReadVariables(tmpl)
	input := make(map[string]string)

	for _, v := range vars {
		if !strings.HasPrefix(v.Name, "userInput_") {
			continue
		}

		s, err := helper.Ask("Set %q to []: ", v.Name[len("userInput_"):])
		if err != nil {
			return 1, err
		}

		input[v.Name] = s
	}

	tmpl = provider.ReplaceVariablesFunc(tmpl, vars, func(v *provider.Variable) string {
		if s, ok := input[v.Name]; ok {
			return s
		}

		return v.String()
	})

	var m map[string]interface{}

	if err := json.Unmarshal([]byte(tmpl), &m); err != nil {
		return 1, err
	}

	f, err := os.Create(c.String("output"))
	if err != nil {
		return 1, err
	}

	p, err := yaml.Marshal(m)
	if err != nil {
		return 1, err
	}

	_, err = io.Copy(f, bytes.NewReader(p))
	err = nonil(err, f.Close())

	if err != nil {
		return 1, err
	}

	fmt.Printf("\nTemplate successfully written to %s.\n", f.Name())

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
