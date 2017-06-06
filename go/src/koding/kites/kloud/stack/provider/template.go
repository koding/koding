package provider

import (
	"bytes"
	"encoding/json"
	"errors"
	"strings"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/utils/object"

	"github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl/ast"
	"github.com/hashicorp/hcl/json/parser"
	"github.com/hashicorp/hil"
	"github.com/hashicorp/terraform/config"
	"github.com/koding/logging"
)

// Template represents a HCL template.
type Template struct {
	Resource map[string]interface{} `json:"resource,omitempty"`
	Provider map[string]interface{} `json:"provider,omitempty"`
	Variable map[string]interface{} `json:"variable,omitempty"`
	Output   map[string]interface{} `json:"output,omitempty"`

	node *ast.ObjectList
	b    *object.Builder
	log  logging.Logger
}

// newTerraformTemplate parses the content and returns a terraformTemplate
// instance
func ParseTemplate(content string, log logging.Logger) (*Template, error) {
	template := &Template{
		Resource: make(map[string]interface{}),
		Provider: make(map[string]interface{}),
		Variable: make(map[string]interface{}),
		Output:   make(map[string]interface{}),
		b: &object.Builder{
			Tag:       "hcl",
			Sep:       "_",
			Recursive: true,
		},
		log: log,
	}

	err := json.Unmarshal([]byte(content), &template)
	if err != nil {
		return nil, err
	}

	if err := template.hclParse(content); err != nil {
		return nil, err
	}

	return template, nil
}

// hclParse parses the given JSON input and updates the internal hcl object
// representation
func (t *Template) hclParse(jsonIn string) error {
	file, err := parser.Parse([]byte(jsonIn))
	if err != nil {
		return err
	}

	if node, ok := file.Node.(*ast.ObjectList); ok {
		t.node = node
	} else {
		return errors.New("template should be of type objectList")
	}

	return nil
}

// hclUpdate update the internal hcl object
func (t *Template) hclUpdate() error {
	out, err := t.JsonOutput()
	if err != nil {
		return err
	}

	return t.hclParse(out)
}

// DecodeProvider decodes the provider block to the given out struct
func (t *Template) DecodeProvider(out interface{}) error {
	return t.decode("provider", out)
}

// DecodeResource decodes the resource block to the given out struct
func (t *Template) DecodeResource(out interface{}) error {
	return t.decode("resource", out)
}

// DecodeVariable decodes the resource block to the given out struct
func (t *Template) DecodeVariable(out interface{}) error {
	return t.decode("variable", out)
}

// Flush updates the template internal representation.
func (t *Template) Flush() error {
	return t.hclUpdate()
}

func (t *Template) decode(resource string, out interface{}) error {
	obj := t.node.Filter(resource)
	return hcl.DecodeObject(out, obj)
}

func (t *Template) String() string {
	out, err := t.JsonOutput()
	if err != nil {
		return "<ERROR>"
	}

	return out
}

// JsonOutput returns a JSON formatted output of the template
func (t *Template) JsonOutput() (string, error) {
	var buf bytes.Buffer

	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)

	if err := enc.Encode(t); err != nil {
		return "", err
	}

	return buf.String(), nil
}

// DetectUserVariables parses the template for any ${var.foo}, ${var.bar},
// etc.. user variables. It returns a list of found variables with, example:
// []string{"foo", "bar"}. The returned list only contains unique names, so any
// user variable which declared multiple times is neglected, only the last
// occurrence is being added.
func (t *Template) DetectUserVariables(prefix string) (map[string]string, error) {
	if !strings.HasSuffix(prefix, "_") {
		prefix = prefix + "_"
	}

	out, err := t.JsonOutput()
	if err != nil {
		return nil, err
	}

	// get AST first, it's capable of parsing json
	a, err := hil.Parse(out)
	if err != nil {
		return nil, err
	}

	// read the variables from the given AST. This is basically just iterating
	// over the AST node and does the heavy lifting for us
	vars, err := config.DetectVariables(a)
	if err != nil {
		return nil, err
	}
	// filter out duplicates
	userVars := make(map[string]string, 0)
	for _, v := range vars {
		// be sure we only get userVariables, as there is many ways of
		// declaring variables
		u, ok := v.(*config.UserVariable)
		if !ok {
			continue
		}

		if _, ok = userVars[u.Name]; !ok && strings.HasPrefix(u.Name, prefix) {
			userVars[u.Name] = ""
		}
	}

	return userVars, nil
}

// ShadowVariables shadows the given variables with the given holder. Variables
// need to be in interpolation form, i.e: ${var.foo}
//
// TODO(rjeczalik): Shadow also data.* block after we upgrade to terraform 0.9+.
func (t *Template) ShadowVariables(holder string, vars ...string) error {
	replace := func(s string) string {
		variables := ReadVariables(s)
		if len(variables) == 0 {
			return ""
		}

		var matching []Variable

	lookup:
		for _, variable := range variables {
			for _, name := range vars {
				if variable.Name == name {
					matching = append(matching, variable)
					continue lookup
				}
			}
		}

		if len(matching) == 0 {
			return ""
		}

		return ReplaceVariablesFunc(s, matching, func(v *Variable) string {
			if v.Expression {
				return `"` + holder + `"`
			}
			return holder
		})
	}

	return object.ReplaceFunc(t.Resource, replace)
}

// fillVariables finds variables declared with the given prefix and fills the
// template with empty variables.
func (t *Template) FillVariables(prefix string) error {
	vars, err := t.DetectUserVariables(prefix)
	if err != nil {
		return err
	}

	return t.InjectVariables("", vars)
}

func (t *Template) InjectVariables(prefix string, meta interface{}) error {
	t.inject(prefix, meta)

	return t.hclUpdate()
}

func (t *Template) InjectCredentials(creds ...*stack.Credential) error {
	for _, cred := range creds {
		t.inject(cred.Provider, cred.Credential)
		t.inject(cred.Provider, cred.Bootstrap)
	}

	return t.hclUpdate()
}

func (t *Template) inject(prefix string, meta interface{}) {
	t.log.Debug("Injecting metadata: %# v", meta)

	for k, v := range t.b.New(prefix).Build(meta) {
		// Ignore custom variables prefixed with __ from injecting.
		// The ignored variables may contain interpolations which are
		// not meant to be sent to Terraform.
		if strings.HasPrefix(k, "custom___") {
			t.log.Debug("Not injecting variable: %s=%s", k, v)
			continue
		}

		t.log.Debug("Injecting variable: %s=%v", k, v)

		t.Variable[k] = map[string]interface{}{
			"default": v,
		}
	}
}
