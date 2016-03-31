// Package common provides common operation helpers to the generators
package common

import (
	"strings"
	"text/template"

	"github.com/cihangir/schema"
	"github.com/cihangir/stringext"
)

// TemplateFuncs provides utility functions for template operations
var TemplateFuncs = template.FuncMap{
	"Pointerize":              stringext.Pointerize,
	"ToLower":                 strings.ToLower,
	"ToUpper":                 strings.ToUpper,
	"Join":                    strings.Join,
	"ToLowerFirst":            stringext.ToLowerFirst,
	"ToUpperFirst":            stringext.ToUpperFirst,
	"AsComment":               stringext.AsComment,
	"DepunctWithInitialUpper": stringext.DepunctWithInitialUpper,
	"DepunctWithInitialLower": stringext.DepunctWithInitialLower,
	"Equal":                   stringext.Equal,
	"ToFieldName":             stringext.ToFieldName,
	"Argumentize":             schema.Argumentize,
	"SortedObjectSchemas":     SortedObjectSchemas,
	"SortedSchema":            schema.SortedSchema,
}
