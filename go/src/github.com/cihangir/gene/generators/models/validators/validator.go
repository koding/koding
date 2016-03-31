package validators

import (
	"bytes"
	"fmt"
	"sort"
	"strings"

	"github.com/cihangir/gene/writers"
	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

// Generate generates the validators for the the given schema
func Generate(s *schema.Schema) ([]byte, error) {
	validators := make([]string, 0)
	// schemaName := p.Title
	schemaFirstChar := stringext.Pointerize(s.Title)

	for k, property := range s.Properties {
		key := stringext.DepunctWithInitialUpper(k)
		switch property.Type {
		case "string":
			if property.MinLength != 0 {
				validator := fmt.Sprintf("govalidator.MinLength(%s.%s, %d)", schemaFirstChar, key, property.MinLength)
				validators = append(validators, validator)
			}

			if property.MaxLength != 0 {
				validator := fmt.Sprintf("govalidator.MaxLength(%s.%s, %d)", schemaFirstChar, key, property.MaxLength)
				validators = append(validators, validator)
			}

			if property.Pattern != "" {
				validator := fmt.Sprintf("govalidator.Pattern(%s.%s, \"%s\")", schemaFirstChar, key, property.Pattern)
				validators = append(validators, validator)
			}

			if len(property.Enum) > 0 {
				generatedEnums := make([]string, len(property.Enum))
				for i, enum := range property.Enum {
					k := stringext.DepunctWithInitialUpper(key)
					generatedEnums[i] = s.Title + k + "." + stringext.DepunctWithInitialUpper(enum)
				}
				validator := fmt.Sprintf("govalidator.OneOf(%s.%s, []string{\n%s,\n})", schemaFirstChar, key, strings.Join(generatedEnums, ",\n"))
				validators = append(validators, validator)
			}

			// TODO impplement this one
			switch property.Format {
			case "date-time":
				// _, err := time.Parse(time.RFC3339, s)
				validator := fmt.Sprintf("govalidator.Date(%s.%s)", schemaFirstChar, key)
				validators = append(validators, validator)
			}

		case "integer", "number":

			// todo implement exclusive min/max

			if property.Minimum != 0 {
				validator := fmt.Sprintf("govalidator.Min(float64(%s.%s), %f)", schemaFirstChar, key, property.Minimum)
				validators = append(validators, validator)
			}

			if property.Maximum != 0 {
				validator := fmt.Sprintf("govalidator.Max(float64(%s.%s), %f)", schemaFirstChar, key, property.Maximum)
				validators = append(validators, validator)
			}

			// multipleOf:
			if property.MultipleOf != 0 {
				validator := fmt.Sprintf("govalidator.MultipleOf(float64(%s.%s), %f)", schemaFirstChar, key, property.MultipleOf)
				validators = append(validators, validator)
			}
		}
	}

	if len(validators) == 0 {
		return nil, nil
	}

	templ := `
// Validate validates the %s struct
func (%s *%s) Validate() error {
	return govalidator.NewMulti(%s).Validate()
}`

	sslice := sort.StringSlice(validators)
	sslice.Sort()

	res := fmt.Sprintf(
		templ,
		s.Title,
		stringext.Pointerize(s.Title),
		s.Title,
		strings.Join(sslice, ",\n"),
	)

	return writers.Clear(*bytes.NewBufferString(res))
}
