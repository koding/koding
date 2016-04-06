package statements

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/utils"
	"github.com/cihangir/geneddl"
	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

// Generator generates the basic CRUD statements.
type Generator struct{}

// Generate generates the basic CRUD statements for the models
func (g *Generator) Generate(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	var outputs []common.Output
	
	moduleName := stringext.ToFieldName(s.Title)

	settings := geneddl.GenerateSettings(geneddl.GeneratorName, moduleName, s)

	for _, def := range common.SortedObjectSchemas(s.Definitions) {

		settingsDef := geneddl.SetDefaultSettings(geneddl.GeneratorName, settings, def)
		settingsDef.Set("tableName", stringext.ToFieldName(def.Title))

		f, err := GenerateModelStatements(context, settingsDef, def)
		if err != nil {
			return outputs, err
		}

		outputs = append(outputs, common.Output{
			Content: f,
			Path: fmt.Sprintf(
				"%s%s_statements.go",
				context.Config.Target,
				strings.ToLower(def.Title),
			),
		})

	}

	return outputs, nil
}

// GenerateModelStatements generates the CRUD statements for the model struct
func GenerateModelStatements(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	packageLine, err := GeneratePackage(context, settings, s)
	if err != nil {
		return nil, err
	}

	createStatements, err := GenerateCreate(context, settings, s)
	if err != nil {
		return nil, err
	}

	updateStatements, err := GenerateUpdate(context, settings, s)
	if err != nil {
		return nil, err
	}

	deleteStatements, err := GenerateDelete(context, settings, s)
	if err != nil {
		return nil, err
	}

	selectStatements, err := GenerateSelect(context, settings, s)
	if err != nil {
		return nil, err
	}

	tableName, err := GenerateTableName(context, settings, s)
	if err != nil {
		return nil, err
	}

	var buf bytes.Buffer
	buf.Write(packageLine)
	buf.Write(createStatements)
	buf.Write(updateStatements)
	buf.Write(deleteStatements)
	buf.Write(selectStatements)
	buf.Write(tableName)

	return utils.Clear(buf)
}

// GeneratePackage generates the imports according to the schema.
// TODO remove this function
func GeneratePackage(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	temp := template.New("package.tmpl")
	if _, err := temp.Parse(PackageTemplate); err != nil {
		return nil, err
	}

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "package.tmpl", data); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

// PackageTemplate holds the template for the packages of the models
var PackageTemplate = `// Generated struct for {{.Schema.Title}}.
package models
`
