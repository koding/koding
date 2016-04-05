package schema

import (
	"bytes"
	"fmt"

	"github.com/cihangir/stringext"
)

// Resolve resolves reference inside the schema.
func (s *Schema) Resolve(r *Schema) *Schema {
	if r == nil {
		r = s
	}

	for n, d := range s.Definitions {
		if d.Title == "" {
			d.Title = n
		}
		s.Definitions[n] = d.Resolve(r)
	}
	for n, p := range s.Properties {
		if p.Title == "" {
			p.Title = n
		}
		s.Properties[n] = p.Resolve(r)
	}
	for n, f := range s.Functions {
		if f.Title == "" {
			f.Title = n
		}
		s.Functions[n] = f.Resolve(r)
	}
	for n, p := range s.PatternProperties {
		s.PatternProperties[n] = p.Resolve(r)
	}
	for n, p := range s.Items {
		s.Items[n] = p.Resolve(r)
	}
	if s.Ref != nil {
		s = s.Ref.Resolve(r)
	}
	if len(s.OneOf) > 0 {
		s = s.OneOf[0].Ref.Resolve(r)
	}
	if len(s.AnyOf) > 0 {
		s = s.AnyOf[0].Ref.Resolve(r)
	}
	for _, l := range s.Links {
		l.Resolve(r)
	}

	for route, handlers := range s.Paths {
		for verb, handler := range handlers {
			for parameterIndex, parameter := range handler.Parameters {
				if parameter.Schema == nil {
					continue
				}

				handler.Parameters[parameterIndex].Schema = parameter.Schema.Resolve(r)
			}

			for responseCode, response := range handler.Responses {
				if response == nil {
					continue
				}

				handler.Responses[responseCode] = response.Resolve(r)
			}

			s.Paths[route][verb] = handler
		}
	}

	return s
}

// Types returns the array of types described by this schema.
func (s *Schema) Types() (types []string) {
	if arr, ok := s.Type.([]interface{}); ok {
		for _, v := range arr {
			types = append(types, v.(string))
		}
	} else if str, ok := s.Type.(string); ok {
		types = append(types, str)
	} else {
		panic(fmt.Sprintf("unknown type %v", s.Type))
	}
	return types
}

// GoType returns the Go type for the given schema as string.
func (s *Schema) GoType() string {
	return s.goType(true, true)
}

// IsCustomType returns true if the schema declares a custom type.
func (s *Schema) IsCustomType() bool {
	return len(s.Properties) > 0
}

func (s *Schema) goType(required bool, force bool) (goType string) {
	// Resolve JSON reference/pointer
	types := s.Types()
	for _, kind := range types {
		switch kind {
		case booleanConst:
			goType = boolConst
		case stringConst:
			switch s.Format {
			case "date-time":
				goType = "time.Time"
			default:
				goType = stringConst
			}
			// put this out of the switch statement
		case numberConst:
			// There is a bias toward networking-related formats in the JSON
			// Schema specification, most likely due to its heritage in web
			// technologies. However, custom formats may also be used, as long
			// as the parties exchanging the JSON documents also exchange
			// information about the custom format types. A JSON Schema
			// validator will ignore any format type that it does not
			// understand.
			if s.Format != "" {
				goType = s.Format
			} else {
				goType = "float64"
			}
		case integerConst, intConst:
			goType = intConst
		case "any":
			goType = "interface{}"
		case arrayConst:
			if len(s.Items) == 1 {
				goType = "[]" + s.Items[0].goType(required, force)
			} else {
				goType = "[]interface{}"
			}
		case "object", "config":
			// Check if patternProperties exists.
			if s.PatternProperties != nil {
				for _, prop := range s.PatternProperties {
					goType = fmt.Sprintf("map[string]%s", prop.GoType())
					break // We don't support more than one pattern for now.
				}
				continue
			}
			buf := bytes.NewBufferString("struct {")
			for _, name := range SortedKeys(s.Properties) {
				prop := s.Properties[name]
				req := stringext.Contains(name, s.Required)
				templates.ExecuteTemplate(buf, "field.tmpl", struct {
					Definition *Schema
					Name       string
					Required   bool
					Type       string
				}{
					Definition: prop,
					Name:       name,
					Required:   req,
					Type:       prop.goType(req, force),
				})
			}

			buf.WriteString("}")
			goType = buf.String()
		case "null":
			continue
		case "error":
			goType = "error"
		case "custom":
			goType = s.Format
		default:
			panic("unknown field")
		}
	}
	if goType == "" {
		panic(fmt.Sprintf("type not found : %s", types))
	}
	// Types allow null
	if stringext.Contains("null", types) || !(required || force) {
		return "*" + goType
	}
	return goType
}

// URL returns schema base URL.
func (s *Schema) URL() string {
	for _, l := range s.Links {
		if l.Rel == "self" {
			return l.HRef.String()
		}
	}
	return ""
}

// // Values creates the value string
// func Values(n string, s *Schema, l *Link) string {
// 	v := s.Values(n, l)
// 	return strings.Join(v, ", ")
// }

func goType(p *Schema) string {
	return p.GoType()
}
