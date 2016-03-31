package geneddl

import (
	"bytes"
	"fmt"
	"os"
	"strings"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineSequence creates definition for sequences
func DefineTable(context *common.Context, settings schema.Generator, s *schema.Schema) ([]byte, error) {
	context.TemplateFuncs["GenerateSQLField"] = GenerateSQLField

	temp := template.New("create_table.tmpl").Funcs(context.TemplateFuncs)
	if _, err := temp.Parse(TableTemplate); err != nil {
		return nil, err
	}

	var buf bytes.Buffer

	data := struct {
		Context    *common.Context
		Schema     *schema.Schema
		Properties []*schema.Schema
		Settings   schema.Generator
	}{
		Context:    context,
		Schema:     s,
		Properties: schema.SortedSchema(s.Properties),
		Settings:   settings,
	}

	if err := temp.ExecuteTemplate(&buf, "create_table.tmpl", data); err != nil {
		return nil, err
	}

	return clean(buf.Bytes()), nil
}

// TableTemplate holds the template for sequences
var TableTemplate = `{{$settings := .Settings}}{{$context := .Context}}-- ----------------------------
--  Table structure for {{$settings.schemaName}}.{{$settings.tableName}}
-- ----------------------------
DROP TABLE IF EXISTS "{{$settings.schemaName}}"."{{$settings.tableName}}";
CREATE TABLE "{{$settings.schemaName}}"."{{$settings.tableName}}" (
{{range $key, $value := .Properties}}
    {{GenerateSQLField $context $settings $value}}
{{end}}
) WITH (OIDS = FALSE);-- end schema creation
GRANT {{Join $settings.grants ", "}} ON "{{$settings.schemaName}}"."{{$settings.tableName}}" TO "{{$settings.roleName}}";
`

// DefineTable creates a definition line for a given coloumn
func GenerateSQLField(context *common.Context, settings schema.Generator, s *schema.Schema) (res string) {
	propertyName := s.Title
	schemaName := settings.Get("schemaName").(string)
	tableName := settings.Get("tableName").(string)

	property := s

	fieldName := context.FieldNameFunc(propertyName) // transpiled version of property
	if property.Title != "" {
		fieldName = context.FieldNameFunc(property.Title)
	}

	fieldType := "" // will hold the type for coloumn

	switch strings.ToLower(property.Type.(string)) {
	case "boolean":
		fieldType = "BOOLEAN"
	case "string":
		switch property.Format {
		case "date-time":
			fieldType = "TIMESTAMP (6) WITH TIME ZONE"
		case "UUID":
			fieldType = "UUID"
		default:
			typeName := "TEXT"
			if property.MaxLength > 0 {
				// if schema defines a max length, no need to use text
				typeName = fmt.Sprintf("VARCHAR (%d)", property.MaxLength)
			}

			fieldType = fmt.Sprintf("%s COLLATE \"default\"", typeName)
		}
	case "number":
		fieldType = "NUMERIC"

		switch property.Format {
		case "int64", "uint64":
			fieldType = "BIGINT"
		case "integer", "int", "int32", "uint", "uint32":
			fieldType = "INTEGER"
		case "int8", "uint8", "int16", "uint16":
			fieldType = "SMALLINT"
		case "float32", "float64":
			fieldType = "NUMERIC"
		}
	case "any":
		panic("should specify type")
	case "array":
		panic("array not supported")
	case "object", "config":
		// TODO implement embedded struct table creation
		res = ""
	case "null":
		res = ""
	case "error":
		res = ""
	case "custom":
		res = ""
	default:
		panic("unknown field")
	}

	// override if it is an enum field
	if len(property.Enum) > 0 {
		fieldType = fmt.Sprintf(
			"%q.\"%s_%s_enum\"",
			schemaName,
			context.FieldNameFunc(tableName),
			context.FieldNameFunc(propertyName),
		)
	}

	res = fmt.Sprintf(
		"%q %s %s %s %s,",
		// first, name comes
		fieldName,
		// then type of the coloumn
		fieldType,
		//  generate default value if exists
		generateDefaultValue(schemaName, fieldName, tableName, property),
		// generate not null statement, if required
		generateNotNull(s, propertyName),
		// generate validators
		generateCheckStatements(tableName, fieldName, property),
	)

	return res
}

// generateDefaultValue generates `default` string for given coloumn
func generateDefaultValue(schemaName string, propertyName, tableName string, s *schema.Schema) string {
	// if property is id, use sequence generator as default value
	if propertyName == "id" {
		return fmt.Sprintf("DEFAULT nextval('%s.%s_id_seq' :: regclass) ", schemaName, tableName)
	}

	if s.Default == nil {
		return ""
	}

	if len(s.Enum) > 0 {
		// enums should be a valud enum string
		if !common.IsIn(s.Default.(string), s.Enum...) {
			fmt.Printf("%s not a valid enum", s.Default)
			os.Exit(1)
		}

		return fmt.Sprintf("DEFAULT '%s'", s.Default)
	}

	def := ""
	switch s.Default.(type) {
	case float64, float32, int16, int32, int, int64, uint16, uint32, uint, uint64, bool:
		def = fmt.Sprintf("%v", s.Default)
	default:
		def = fmt.Sprintf("%v", s.Default)

		// if default is a function call, use it
		if strings.HasSuffix(def, "()") {
			return fmt.Sprintf("DEFAULT %s", def)
		}

		// it is string, quote it
		def = fmt.Sprintf("'%v'", s.Default)
	}

	return fmt.Sprintf("DEFAULT %s", strings.ToUpper(def))
}

// generateNotNull if field is in required values, set NOT NULL
func generateNotNull(s *schema.Schema, name string) string {
	if schema.Required(name, s) {
		return "NOT NULL"
	}

	return ""
}

// generateCheckStatements generates validators
func generateCheckStatements(tableName, fieldName string, property *schema.Schema) string {
	chekcs := ""
	switch strings.ToLower(property.Type.(string)) {
	case "string":
		if property.MinLength > 0 {
			chekcs += fmt.Sprintf(
				"\n\t\tCONSTRAINT \"check_%s_%s_min_length_%d\" CHECK (char_length(%q) > %d )",
				tableName,
				fieldName,
				property.MinLength,
				fieldName,
				property.MinLength,
			)
		}

		if property.Pattern != "" {
			chekcs += fmt.Sprintf(
				"\n\t\tCONSTRAINT \"check_%s_%s_pattern\" CHECK (%q ~ '%s')",
				tableName,
				fieldName,
				fieldName,
				property.Pattern,
			)
		}
		// no need to check for max length, we already create coloumn with max length
	case "number":
		if property.MultipleOf > 0 {
			chekcs += fmt.Sprintf(
				"\n\t\tCONSTRAINT \"check_%s_%s_multiple_of_%d\" CHECK ((%q %% %f) = 0)",
				tableName,
				fieldName,
				int64(property.MultipleOf), // do not use dot in check constraint
				fieldName,
				property.MultipleOf,
			)
		}

		if property.Maximum > 0 {
			checker := "<"
			str := "lt"

			if !property.ExclusiveMaximum {
				checker += "="
				str += "e"
			}

			chekcs += fmt.Sprintf(
				"\n\t\tCONSTRAINT \"check_%s_%s_%s_%d\" CHECK (%q %s %f)",
				tableName,
				fieldName,
				str,
				int64(property.Maximum),
				fieldName,
				checker,
				property.Maximum,
			)
		}

		if property.Minimum > 0 {
			checker := ">"
			str := "gt"

			if !property.ExclusiveMinimum {
				checker += "="
				str += "e"
			}

			chekcs += fmt.Sprintf(
				"\n\t\tCONSTRAINT \"check_%s_%s_%s_%d\" CHECK (%q %s %f)",
				tableName,
				fieldName,
				str,
				int64(property.Maximum),
				fieldName,
				checker,
				property.Maximum,
			)
		}
	}

	return chekcs
}
