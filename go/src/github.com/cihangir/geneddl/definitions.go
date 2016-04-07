// Package geneddl provides DDL generation for json schema
package geneddl

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/utils"
	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

// GeneratorName holds generator name
const GeneratorName = "ddl"

// Generator provides DDL generation
type Generator struct {
	DatabaseName  string
	SchemaName    string
	TableName     string
	RoleName      string
	FieldNameCase string `default:"snake"`
}

// New is the constructor for generator struct

// Generate generates the basic CRUD statements for the models
func (g *Generator) Generate(req *common.Req, res *common.Res) error {
	context := req.Context

	if context == nil || context.Config == nil || !common.IsIn(GeneratorName, context.Config.Generators...) {
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

	if req.Schema.Title == "" {
		return errors.New("Title should be set")
	}

	outputs := make([]common.Output, 0)

	moduleName := stringext.ToFieldName(req.Schema.Title)

	settings := GenerateSettings(GeneratorName, moduleName, req.Schema)
	settings.SetNX("rootPathPrefix", "db")
	rootPathPrefix := settings.Get("rootPathPrefix").(string)
	fullPathPrefix := req.Context.Config.Target + rootPathPrefix + "/"
	settings.Set("fullPathPrefix", fullPathPrefix)

	for _, name := range schema.SortedKeys(req.Schema.Definitions) {
		def := req.Schema.Definitions[name]

		// schema should have our generator
		if !def.Generators.Has(GeneratorName) {
			continue
		}

		settingsDef := SetDefaultSettings(GeneratorName, settings, def)
		settingsDef.Set("tableName", stringext.ToFieldName(def.Title))

		//
		// generate roles
		//
		role, err := DefineRole(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: role,
			Path: fmt.Sprintf(
				"%s/001-%s_roles.sql",
				fullPathPrefix,
				settingsDef.Get("databaseName").(string),
			),
			DoNotFormat: true,
		})

		//
		// generate database
		//
		db, err := DefineDatabase(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: db,
			Path: fmt.Sprintf(
				"%s/002-%s_database.sql",
				fullPathPrefix,
				settingsDef.Get("databaseName").(string),
			),
			DoNotFormat: true,
		})

		//
		// generate extenstions
		//
		extenstions, err := DefineExtensions(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: extenstions,
			Path: fmt.Sprintf(
				"%s/003-%s_extensions.sql",
				fullPathPrefix,
				settingsDef.Get("databaseName").(string)),
			DoNotFormat: true,
		})

		//
		// generate schema
		//
		sc, err := DefineSchema(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: sc,
			Path: fmt.Sprintf(
				"%s/%s/004-schema.sql",
				fullPathPrefix,
				settingsDef.Get("schemaName").(string),
			),
			DoNotFormat: true,
		})

		//
		// generate sequences
		//
		sequence, err := DefineSequence(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: sequence,
			Path: fmt.Sprintf(
				"%s/%s/005-%s-sequence.sql",
				fullPathPrefix,
				settingsDef.Get("schemaName").(string),
				settingsDef.Get("tableName").(string),
			),
			DoNotFormat: true,
		})

		//
		// generate types
		//
		types, err := DefineTypes(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: types,
			Path: fmt.Sprintf(
				"%s/%s/006-%s-types.sql",
				fullPathPrefix,
				settingsDef.Get("schemaName").(string),
				settingsDef.Get("tableName").(string),
			),
			DoNotFormat: true,
		})

		//
		// generate tables
		//
		table, err := DefineTable(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: table,
			Path: fmt.Sprintf(
				"%s/%s/007-%s-table.sql",
				fullPathPrefix,
				settingsDef.Get("schemaName").(string),
				settingsDef.Get("tableName").(string),
			),
			DoNotFormat: true,
		})

		//
		// generate constraints
		//
		constraints, err := DefineConstraints(settingsDef, def)
		if err != nil {
			return err
		}

		outputs = append(outputs, common.Output{
			Content: constraints,
			Path: fmt.Sprintf(
				"%s/%s/008-%s-constraints.sql",
				fullPathPrefix,
				settingsDef.Get("schemaName").(string),
				settingsDef.Get("tableName").(string),
			),
			DoNotFormat: true,
		})
	}

	res.Output = outputs
	return nil
}

// GenerateSettings generates settings for the ddl package
func GenerateSettings(genName string, moduleName string, s *schema.Schema) schema.Generator {
	settings, ok := s.Generators.Get(genName)
	if !ok {
		settings = schema.Generator{}
	}
	settings.SetNX("databaseName", stringext.ToFieldName(moduleName))
	settings.SetNX("schemaName", stringext.ToFieldName(moduleName))
	settings.SetNX("tableName", stringext.ToFieldName(s.Title))
	settings.SetNX("roleName", stringext.ToFieldName(moduleName))

	// convert []interface to []string
	grants := settings.GetWithDefault("grants", []string{"ALL"})
	grantsI, ok := grants.([]interface{})
	grantsS := make([]string, 0)

	if ok {
		for _, t := range grantsI {
			grantsS = append(grantsS, t.(string))
		}
	} else {
		grantsS = grants.([]string)
	}

	settings.Set("grants", grantsS)

	return settings
}

// SetDefaultSettings sets the default values for the settings
func SetDefaultSettings(genName string, defaultSettings schema.Generator, s *schema.Schema) schema.Generator {
	settings, _ := s.Generators.Get(genName)

	settings.SetNX("databaseName", defaultSettings.Get("databaseName").(string))
	settings.SetNX("schemaName", defaultSettings.Get("schemaName").(string))
	settings.SetNX("tableName", defaultSettings.Get("tableName").(string))
	settings.SetNX("roleName", defaultSettings.Get("roleName").(string))

	// convert []interface to []string
	grants := settings.GetWithDefault("grants", defaultSettings.Get("grants").([]string))
	grantsI, ok := grants.([]interface{})
	grantsS := make([]string, 0)

	if ok {
		for _, t := range grantsI {
			grantsS = append(grantsS, t.(string))
		}
	} else {
		grantsS = grants.([]string)
	}

	settings.Set("grants", grantsS)

	return settings
}

func clean(b []byte) []byte {
	b = utils.NewLinesRegex.ReplaceAll(b, []byte(""))

	// convert tabs to 4 spaces
	b = bytes.Replace(b, []byte("\t"), []byte("    "), -1)

	// clean extra spaces
	b = bytes.Replace(b, []byte("  ,"), []byte(","), -1)
	b = bytes.Replace(b, []byte(" ,"), []byte(","), -1)

	// replace last trailing comma
	b = bytes.Replace(b, []byte(",\n)"), []byte("\n)"), -1)

	return b
}
