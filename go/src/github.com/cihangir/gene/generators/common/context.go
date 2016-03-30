package common

import (
	"strings"
	"text/template"

	"github.com/cihangir/gene/config"
	"github.com/cihangir/stringext"
)

type Context struct {
	Config *config.Config

	// Funcs
	ModuleNameFunc func(string) string
	FileNameFunc   func(string) string
	FieldNameFunc  func(string) string

	// TemplateFuncs
	TemplateFuncs template.FuncMap
}

func NewContext() *Context {
	return &Context{
		// Funcs
		ModuleNameFunc: strings.ToLower,
		FileNameFunc:   strings.ToLower,
		FieldNameFunc:  stringext.ToFieldName,
		Config:         &config.Config{},
		TemplateFuncs:  TemplateFuncs,
	}
}
