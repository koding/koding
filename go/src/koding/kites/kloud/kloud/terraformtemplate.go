package kloud

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strings"

	"github.com/fatih/structs"
	hclmain "github.com/hashicorp/hcl"
	"github.com/hashicorp/hcl/hcl"
	hcljson "github.com/hashicorp/hcl/json"
)

type terraformTemplate struct {
	Resource struct {
		Aws_Instance map[string]map[string]interface{} `json:"aws_instance"`
	} `json:"resource,omitempty"`
	// Provider map[string]map[string]interface{} `json:"provider,omitempty"`
	Provider struct {
		Aws struct {
			Region    string `json:"region"`
			AccessKey string `json:"access_key"`
			SecretKey string `json:"secret_key"`
		} `json:"aws"`
	} `json:"provider"`
	Variable map[string]map[string]interface{} `json:"variable,omitempty"`
	Output   map[string]map[string]interface{} `json:"output,omitempty"`

	h *hcl.Object `json:"-"`
}

func newTerraformTemplate(content string) (*terraformTemplate, error) {
	var template *terraformTemplate
	err := json.Unmarshal([]byte(content), &template)
	if err != nil {
		return nil, err
	}

	template.h, err = hcljson.Parse(content)
	if err != nil {
		return nil, err
	}

	return template, nil
}

// DecodeProvider decodes the provider block to the given out struct
func (t *terraformTemplate) DecodeProvider(out interface{}) error {
	return t.decode("provider", out)
}

func (t *terraformTemplate) decode(resource string, out interface{}) error {
	obj := t.h.Get(resource, true)
	return hclmain.DecodeObject(out, obj)
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
	out, err := json.MarshalIndent(t, "", "  ")
	if err != nil {
		return "", err
	}

	return string(out), nil
}

func (t *terraformTemplate) injectCustomVariables(prefix string, data map[string]string) {
	for key, val := range data {
		varName := fmt.Sprintf("%s_%s", prefix, key)
		t.Variable[varName] = map[string]interface{}{
			"default": val,
		}
	}
}

func (t *terraformTemplate) injectKodingVariables(data *terraformData) {
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
						newName := varName + "_" + strings.ToLower(f.Name())
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
}
