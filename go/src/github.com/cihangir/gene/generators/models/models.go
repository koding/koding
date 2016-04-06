// Package models creates the models for the modules
package models

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/generators/models/constants"
	"github.com/cihangir/gene/generators/models/constructors"
	"github.com/cihangir/gene/generators/models/validators"
	"github.com/cihangir/gene/utils"
	"github.com/cihangir/schema"
)

// Generator for models
type Generator struct{}

// Generate generates models for schema
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	context := req.Context

	if context == nil || context.Config == nil {
		return nil
	}

	if !common.IsIn("models", context.Config.Generators...) {
		return nil
	}

	if req.Schema == nil {
		if req.SchemaStr == "" {
			return errors.New("both schema and string schema is not set")
		}

		s := &schema.Schema{}
		if err := json.Unmarshal([]byte(req.SchemaStr), s); err != nil {
			return err
		}

		req.Schema = s.Resolve(nil)
	}

	settings, ok := req.Schema.Generators.Get("models")
	if !ok {
		settings = schema.Generator{}
	}

	settings.SetNX("rootPathPrefix", "models")
	rootPathPrefix := settings.Get("rootPathPrefix").(string)
	fullPathPrefix := req.Context.Config.Target + rootPathPrefix + "/"
	settings.Set("fullPathPrefix", fullPathPrefix)

	// TODO(cihangir) remove this statement when Process transition is complete
	req.Context.Config.Target = fullPathPrefix

	var outputs []common.Output
	
	for _, def := range common.SortedObjectSchemas(req.Schema.Definitions) {
		f, err := GenerateModel(def)
		if err != nil {
			return err
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
				if incoming.Type == nil {
					return fmt.Errorf("Type should be set on %+v", incoming)
				}

				if incoming.Type.(string) == "object" {
					f, err := GenerateModel(incoming)
					if err != nil {
						return err
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
				if outgoing.Type == nil {
					return fmt.Errorf("Type should be set on %+v", outgoing)
				}

				if outgoing.Type.(string) == "object" {
					f, err := GenerateModel(outgoing)
					if err != nil {
						return err
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

	res.Output = outputs
	return nil
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

	return utils.Clear(buf)
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

	return utils.Clear(buf)
}
