package kloud

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"

	"github.com/fatih/structs"
	"github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl/ast"
	"github.com/hashicorp/hcl/json/parser"
	"github.com/hashicorp/terraform/config"
	"github.com/hashicorp/terraform/config/lang"
)

type terraformTemplate struct {
	Resource map[string]interface{} `json:"resource,omitempty"`
	Provider map[string]interface{} `json:"provider,omitempty"`
	Variable map[string]interface{} `json:"variable,omitempty"`
	Output   map[string]interface{} `json:"output,omitempty"`

	node *ast.ObjectList `json:"-"`
}

// newTerraformTemplate parses the content and returns a terraformTemplate
// instance
func newTerraformTemplate(content string) (*terraformTemplate, error) {
	template := &terraformTemplate{
		Resource: make(map[string]interface{}),
		Provider: make(map[string]interface{}),
		Variable: make(map[string]interface{}),
		Output:   make(map[string]interface{}),
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
func (t *terraformTemplate) hclParse(jsonIn string) error {
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
func (t *terraformTemplate) hclUpdate() error {
	out, err := t.jsonOutput()
	if err != nil {
		return err
	}

	return t.hclParse(out)
}

// DecodeProvider decodes the provider block to the given out struct
func (t *terraformTemplate) DecodeProvider(out interface{}) error {
	return t.decode("provider", out)
}

// DecodeResource decodes the resource block to the given out struct
func (t *terraformTemplate) DecodeResource(out interface{}) error {
	return t.decode("resource", out)
}

// DecodeVariable decodes the resource block to the given out struct
func (t *terraformTemplate) DecodeVariable(out interface{}) error {
	return t.decode("variable", out)
}

func (t *terraformTemplate) decode(resource string, out interface{}) error {
	obj := t.node.Filter(resource)
	return hcl.DecodeObject(out, obj)
}

func (t *terraformTemplate) String() string {
	out, err := t.jsonOutput()
	if err != nil {
		return "<ERROR>"
	}

	return out
}

// jsonOutput returns a JSON formatted output of the template
func (t *terraformTemplate) jsonOutput() (string, error) {
	out, err := json.MarshalIndent(&t, "", "  ")
	if err != nil {
		return "", err
	}

	// replace escaped brackets and ampersand. the marshal package is encoding
	// them automtically so it can be safely processed inside HTML scripts, but
	// we don't need it.
	out = bytes.Replace(out, []byte("\\u003c"), []byte("<"), -1)
	out = bytes.Replace(out, []byte("\\u003e"), []byte(">"), -1)
	out = bytes.Replace(out, []byte("\\u0026"), []byte("&"), -1)

	return string(out), nil
}

// detectUserVariables parses the template for any ${var.foo}, ${var.bar},
// etc.. user variables. It returns a list of found variables with, example:
// []string{"foo", "bar"}. The returned list only contains unique names, so any
// user variable which declared multiple times is neglected, only the last
// occurence is being added.
func (t *terraformTemplate) detectUserVariables() ([]string, error) {
	out, err := t.jsonOutput()
	if err != nil {
		return nil, err
	}

	// get AST first, it's capable of parsing json
	a, err := lang.Parse(out)
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
	set := make(map[string]bool, 0)
	for _, v := range vars {
		// be sure we only get userVariables, as there is many ways of
		// declaring variables
		u, ok := v.(*config.UserVariable)
		if !ok {
			continue
		}

		if !set[u.Name] {
			set[u.Name] = true
		}
	}

	userVars := []string{}
	for u := range set {
		userVars = append(userVars, u)
	}

	return userVars, nil
}

// shadowVariables shadows the given variables with the given holder. Variables
// need to be in interpolation form, i.e: ${var.foo}
func (t *terraformTemplate) shadowVariables(holder string, vars ...string) error {
	for i, item := range t.node.Items {
		key := item.Keys[0].Token.Text
		switch key {
		case "resource", `"resource"`:
			// check for both, quoted and unquoted
		default:
			// We are going to shadow any variable inside the resource,
			// anything else doesn't matter.
			continue
		}

		item.Val = ast.Rewrite(item.Val, func(n ast.Node) ast.Node {
			switch t := n.(type) {
			case *ast.LiteralType:
				for _, v := range vars {
					iVar := fmt.Sprintf(`${var.%s}`, v)
					t.Token.Text = strings.Replace(t.Token.Text, iVar, holder, -1)
				}

				n = t
			}
			return n
		})

		ast.Walk(item.Val, func(n ast.Node) bool {
			switch t := n.(type) {
			case *ast.LiteralType:
				fmt.Printf("t.Token.Text = %+v\n", t.Token.Text)
			}
			return true
		})

		t.node.Items[i] = item
	}

	return hcl.DecodeObject(&t.Resource, t.node.Filter("resource"))
}

func (t *terraformTemplate) setAwsRegion(region string) error {
	var provider struct {
		Aws struct {
			Region    string
			AccessKey string `hcl:"access_key"`
			SecretKey string `hcl:"secret_key"`
		}
	}

	if err := t.DecodeProvider(&provider); err != nil {
		return err
	}

	if provider.Aws.Region == "" {
		t.Provider["aws"] = map[string]interface{}{
			"region":     region,
			"access_key": provider.Aws.AccessKey,
			"secret_key": provider.Aws.SecretKey,
		}
	} else if !isVariable(provider.Aws.Region) && provider.Aws.Region != region {
		return fmt.Errorf("region is already set as '%s'. Can't override it with: %s",
			provider.Aws.Region, region)
	}

	return t.hclUpdate()
}

// fillVariables finds variables declared with the given prefix and fills the
// template with empty variables.
func (t *terraformTemplate) fillVariables(prefix string) error {
	vars, err := t.detectUserVariables()
	if err != nil {
		return err
	}

	fillVarData := make(map[string]string, 0)
	for _, v := range vars {
		if strings.HasPrefix(v, prefix) {
			fillVarData[strings.TrimPrefix(v, prefix+"_")] = ""
		}
	}

	return t.injectCustomVariables(prefix, fillVarData)
}

func (t *terraformTemplate) injectCustomVariables(prefix string, data map[string]string) error {
	for key, val := range data {
		varName := fmt.Sprintf("%s_%s", prefix, key)
		t.Variable[varName] = map[string]interface{}{
			"default": val,
		}
	}

	return t.hclUpdate()
}

func (t *terraformTemplate) injectKodingVariables(data *kodingData) error {
	var properties = []struct {
		collection string
		fieldToAdd map[string]bool
	}{
		{"User",
			map[string]bool{
				"username": true,
				"email":    true,
			},
		},
		{"Account",
			map[string]bool{
				"profile": true,
			},
		},
		{"Group",
			map[string]bool{
				"title": true,
				"slug":  true,
			},
		},
	}

	for _, p := range properties {
		model, ok := structs.New(data).FieldOk(p.collection)
		if !ok {
			continue
		}

		for _, field := range model.Fields() {
			fieldName := strings.ToLower(field.Name())
			// check if the user set a field tag
			if field.Tag("bson") != "" {
				fieldName = field.Tag("bson")
			}

			exists := p.fieldToAdd[fieldName]

			// we need to declare to call it recursively
			var addVariable func(*structs.Field, string, bool)

			addVariable = func(field *structs.Field, varName string, allow bool) {
				if !allow {
					return
				}

				// nested structs, call again
				if field.Kind() == reflect.Struct {
					for _, f := range field.Fields() {
						fieldName := strings.ToLower(f.Name())
						// check if the user set a field tag
						if f.Tag("bson") != "" {
							fieldName = f.Tag("bson")
						}

						newName := varName + "_" + fieldName
						addVariable(f, newName, true)
					}
					return
				}

				t.Variable[varName] = map[string]interface{}{
					"default": field.Value(),
				}
			}

			varName := "koding_" + strings.ToLower(p.collection) + "_" + fieldName
			addVariable(field, varName, exists)
		}
	}

	return t.hclUpdate()
}
