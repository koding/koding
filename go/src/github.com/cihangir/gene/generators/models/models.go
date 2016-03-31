// Package models creates the models for the modules
package models

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/generators/models/constants"
	"github.com/cihangir/gene/generators/models/constructors"
	"github.com/cihangir/gene/generators/models/validators"
	"github.com/cihangir/gene/writers"
	"github.com/cihangir/schema"
)

type Generator struct{}

func (g *Generator) Generate(context *common.Context, schema *schema.Schema) ([]common.Output, error) {
	outputs := make([]common.Output, 0)

	for _, def := range common.SortedObjectSchemas(schema.Definitions) {
		f, err := GenerateModel(def)
		if err != nil {
			return nil, err
		}

		path := fmt.Sprintf(
			"%s/%s.go",
			context.Config.Target,
			strings.ToLower(def.Title),
		)

		outputs = append(outputs, common.Output{
			Content: f,
			Path:    path,
		})

		for _, funcDef := range def.Functions {
			if incoming, ok := funcDef.Properties["incoming"]; ok {
				if incoming.Type.(string) == "object" {
					f, err := GenerateModel(incoming)
					if err != nil {
						return nil, err
					}

					path := fmt.Sprintf(
						"%s/%s.go",
						context.Config.Target,
						strings.ToLower(incoming.Title),
					)

					outputs = append(outputs, common.Output{
						Content: f,
						Path:    path,
					})
				}
			}

			if outgoing, ok := funcDef.Properties["outgoing"]; ok {

				if outgoing.Type.(string) == "object" {
					f, err := GenerateModel(outgoing)
					if err != nil {
						return nil, err
					}

					path := fmt.Sprintf(
						"%s/%s.go",
						context.Config.Target,
						strings.ToLower(outgoing.Title),
					)

					outputs = append(outputs, common.Output{
						Content: f,
						Path:    path,
					})
				}
			}
		}
	}

	return outputs, nil
}

// GenerateModel generates the model itself
func GenerateModel(s *schema.Schema) ([]byte, error) {
	packageLine, err := GeneratePackage(s)
	if err != nil {
		return nil, err
	}

	consts, err := constants.Generate(s)
	if err != nil {
		return nil, err
	}

	schema, err := GenerateSchema(s)
	if err != nil {
		return nil, err
	}

	constructor, err := constructors.Generate(s)
	if err != nil {
		return nil, err
	}

	validators, err := validators.Generate(s)
	if err != nil {
		return nil, err
	}

	var buf bytes.Buffer
	buf.Write(packageLine)
	buf.Write(consts)
	buf.Write(schema)
	buf.Write(constructor)
	if validators != nil {
		buf.Write(validators)
	}

	return writers.Clear(buf)
}

// GeneratePackage generates the imports according to the schema.
// TODO remove this function
func GeneratePackage(s *schema.Schema) ([]byte, error) {
	temp := template.New("package.tmpl")
	_, err := temp.Parse(PackageTemplate)
	if err != nil {
		return nil, err
	}

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	var buf bytes.Buffer

	err = temp.ExecuteTemplate(&buf, "package.tmpl", data)
	if err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

// GenerateSchema generates the schema.
func GenerateSchema(s *schema.Schema) ([]byte, error) {
	temp := template.New("schema.tmpl")
	temp.Funcs(schema.Helpers)

	_, err := temp.Parse(StructTemplate)
	if err != nil {
		return nil, err
	}

	var buf bytes.Buffer

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	err = temp.ExecuteTemplate(&buf, "schema.tmpl", data)
	if err != nil {
		return nil, err
	}

	return writers.Clear(buf)
}
