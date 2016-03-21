package schema

import (
	"bytes"
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/cihangir/stringext"
)

var newLinesRegex = regexp.MustCompile(`(?m:\s*$)`)

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
		case "boolean":
			goType = "bool"
		case "string":
			switch s.Format {
			case "date-time":
				goType = "time.Time"
			default:
				goType = "string"
			}
			// put this out of the switch statement
		case "number":
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
		case "integer", "int":
			goType = "int"
		case "any":
			goType = "interface{}"
		case "array":
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

// Values returns function return values types.
func (s *Schema) Values(name string, l *Link) []string {
	var values []string
	name = stringext.ToUpperFirst(name)
	switch l.Rel {
	case "destroy", "empty":
		values = append(values, "error")
	case "instances":
		values = append(values, fmt.Sprintf("[]*%s", name), "error")
	default:
		if s.IsCustomType() {
			values = append(values, fmt.Sprintf("*%s", name), "error")
		} else {
			values = append(values, s.GoType(), "error")
		}
	}
	return values
}

// Argumentize returns a string that can be used as an argument into a function
func Argumentize(s interface{}) string {
	switch s.(type) {
	case *Schema:
		sc := s.(*Schema)
		switch sc.Type {
		case "array":
			if len(sc.Items) == 1 {
				switch sc.Items[0].Type {
				case "object":
					return fmt.Sprintf("[]*models.%s", sc.Items[0].Title)
				case "number":
					return fmt.Sprintf("[]%s", sc.Items[0].Format)
				case "string":
					return fmt.Sprintf("[]%s", "string")
				case "boolean":
					return fmt.Sprintf("[]%s", "bool")
				default:
					panic("unsupported argumentize format")
				}
			} else {
				return "[]interface{}"
			}
		case "number":
			return sc.Format
		case "string":
			return "string"
		case "boolean":
			return "bool"
		default:
			return fmt.Sprintf("models.%s", sc.Title)
		}
	case *bool:
		return "bool"
	case *int64:
		return "int64"
	}
	panic("unknown type") // todo return interface instead
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

// Parameters returns function parameters names and types.
func (l *Link) Parameters() ([]string, map[string]string) {
	if l.HRef == nil {
		// No HRef property
		panic(fmt.Errorf("no href property declared for %s", l.Title))
	}
	var order []string
	params := make(map[string]string)
	for _, name := range l.HRef.Order {
		def := l.HRef.Schemas[name]
		order = append(order, name)
		params[name] = def.GoType()
	}
	switch l.Rel {
	case "update", "create":
		order = append(order, "o")
		params["o"] = l.GoType()
	case "instances":
		order = append(order, "lr")
		params["lr"] = "*ListRange"
	}
	return order, params
}

// Resolve resolve link schema and href.
func (l *Link) Resolve(r *Schema) {
	if l.Schema != nil {
		l.Schema = l.Schema.Resolve(r)
	}
	l.HRef.Resolve(r)
}

// GoType returns Go type for the given schema as string.
func (l *Link) GoType() string {
	return l.Schema.goType(true, false)
}

// propertyOrderedKey attaches the methods of Interface, sorting in increasing order.
type propertyOrderedKey struct {
	key           string
	propertyOrder int
}

type propertyOrderedKeys []propertyOrderedKey

func (p propertyOrderedKeys) Len() int           { return len(p) }
func (p propertyOrderedKeys) Less(i, j int) bool { return p[i].propertyOrder < p[j].propertyOrder }
func (p propertyOrderedKeys) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }

func (p propertyOrderedKeys) prependKeysTo(to []string) []string {
	newSlice := make([]string, 0)
	for _, k := range p {
		newSlice = append(newSlice, k.key)
	}

	return append(newSlice, to...)
}

// SortedKeys sorts given schema map according to PropertyOrder property, 0
// valued properties are sort with strings.Sort
func SortedKeys(m map[string]*Schema) (keys []string) {
	unorderedKeys := make([]string, 0)
	orderedProperties := propertyOrderedKeys{}

	for key := range m {
		if m[key].PropertyOrder == 0 {
			unorderedKeys = append(unorderedKeys, key)
		} else {
			orderedProperties = append(orderedProperties, propertyOrderedKey{
				key:           key,
				propertyOrder: m[key].PropertyOrder,
			})
		}
	}

	// sort unordered keys first
	sort.Strings(unorderedKeys)

	// sort order given properties
	sort.Sort(orderedProperties)

	// conbine them
	return orderedProperties.prependKeysTo(unorderedKeys)
}

// SortedSchema sorts given map[string]Schema and returns a slice of Schema
// using SortedKeys function
func SortedSchema(m map[string]*Schema) []*Schema {
	keys := SortedKeys(m)
	ss := make([]*Schema, len(m))
	for i, k := range keys {
		ss[i] = m[k]
	}

	return ss
}

// Args creates arguments string
func Args(h *HRef) string {
	return strings.Join(h.Order, ", ")
}

// Values creates the value string
func Values(n string, s *Schema, l *Link) string {
	v := s.Values(n, l)
	return strings.Join(v, ", ")
}

// Required checks if the given n is a required property
func Required(n string, def *Schema) bool {
	return stringext.Contains(n, def.Required)
}

// Params creates the parameter string for the given link
func Params(l *Link) string {
	var p []string
	order, Params := l.Parameters()
	for _, n := range order {
		p = append(p, fmt.Sprintf("%s %s", stringext.DepunctWithInitialLower(n), Params[n]))
	}
	return strings.Join(p, ", ")
}

func goType(p *Schema) string {
	return p.GoType()
}
