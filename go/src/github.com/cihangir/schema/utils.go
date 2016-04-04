package schema

import (
	"fmt"
	"sort"

	"github.com/cihangir/stringext"
)

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

// Required checks if the given n is a required property
func Required(n string, def *Schema) bool {
	return stringext.Contains(n, def.Required)
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

// Argumentize returns a string that can be used as an argument into a function
func Argumentize(s interface{}) string {
	switch s.(type) {
	case *Schema:
		sc := s.(*Schema)
		switch sc.Type {
		case arrayConst:
			if len(sc.Items) == 1 {
				switch sc.Items[0].Type {
				case objectConst:
					return fmt.Sprintf("[]*models.%s", sc.Items[0].Title)
				case numberConst:
					return fmt.Sprintf("[]%s", sc.Items[0].Format)
				case stringConst:
					return fmt.Sprintf("[]%s", stringConst)
				case booleanConst:
					return fmt.Sprintf("[]%s", "bool")
				default:
					panic(fmt.Sprintf("unsupported argumentize format: %+v", sc))
				}
			} else {
				return "[]interface{}"
			}
		case numberConst:
			return sc.Format
		case stringConst:
			return stringConst
		case booleanConst:
			return boolConst
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

const (
	arrayConst   = "array"
	booleanConst = "boolean"
	boolConst    = "bool"
	numberConst  = "number"
	objectConst  = "object"
	stringConst  = "string"
	integerConst = "integer"
	intConst     = "int"
)
