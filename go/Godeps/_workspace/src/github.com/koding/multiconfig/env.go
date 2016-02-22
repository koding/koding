package multiconfig

import (
	"fmt"
	"os"
	"reflect"
	"strings"

	"github.com/fatih/camelcase"
	"github.com/fatih/structs"
)

// EnvironmentLoader satisifies the loader interface. It loads the
// configuration from the environment variables in the form of
// STRUCTNAME_FIELDNAME.
type EnvironmentLoader struct {
	// Prefix prepends given string to every environment variable
	// {STRUCTNAME}_FIELDNAME will be {PREFIX}_FIELDNAME
	Prefix string

	// CamelCase adds a seperator for field names in camelcase form. A
	// fieldname of "AccessKey" would generate a environment name of
	// "STRUCTNAME_ACCESSKEY". If CamelCase is enabled, the environment name
	// will be generated in the form of "STRUCTNAME_ACCESS_KEY"
	CamelCase bool
}

func (e *EnvironmentLoader) getPrefix(s *structs.Struct) string {
	if e.Prefix != "" {
		return e.Prefix
	}

	return s.Name()
}

// Load loads the source into the config defined by struct s
func (e *EnvironmentLoader) Load(s interface{}) error {
	strct := structs.New(s)

	prefix := e.getPrefix(strct)

	for _, field := range strct.Fields() {
		if err := e.processField(prefix, field); err != nil {
			return err
		}
	}

	return nil
}

// processField gets leading name for the env variable and combines the current
// field's name and generates environemnt variable names recursively
func (e *EnvironmentLoader) processField(prefix string, field *structs.Field) error {
	fieldName := e.generateFieldName(prefix, field)

	switch field.Kind() {
	case reflect.Struct:
		for _, f := range field.Fields() {
			if err := e.processField(fieldName, f); err != nil {
				return err
			}
		}
	default:
		v := os.Getenv(fieldName)
		if v == "" {
			return nil
		}

		if err := fieldSet(field, v); err != nil {
			return err
		}
	}

	return nil
}

// PrintEnvs prints the generated environment variables to the std out.
func (e *EnvironmentLoader) PrintEnvs(s interface{}) {
	strct := structs.New(s)

	prefix := e.getPrefix(strct)

	for _, field := range strct.Fields() {
		e.printField(prefix, field)
	}
}

// printField prints the field of the config struct for the flag.Usage
func (e *EnvironmentLoader) printField(prefix string, field *structs.Field) {
	fieldName := e.generateFieldName(prefix, field)

	switch field.Kind() {
	case reflect.Struct:
		for _, f := range field.Fields() {
			e.printField(fieldName, f)
		}
	default:
		fmt.Println("  ", fieldName)
	}
}

// generateFieldName generates the fiels name combined with the prefix and the
// struct's field name
func (e *EnvironmentLoader) generateFieldName(prefix string, field *structs.Field) string {
	fieldName := strings.ToUpper(field.Name())
	if e.CamelCase {
		fieldName = strings.ToUpper(strings.Join(camelcase.Split(field.Name()), "_"))
	}

	return strings.ToUpper(prefix) + "_" + fieldName
}
