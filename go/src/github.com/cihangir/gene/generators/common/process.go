package common

import (
	"bytes"
	"encoding/json"
	"errors"
	"go/format"
	"strings"
	"text/template"

	"github.com/cihangir/gene/utils"
	"github.com/cihangir/schema"
)

// PostProcessor holds to be applied operations after generation is done.
type PostProcessor func([]byte) []byte

// Op holds the operation information for processing.
type Op struct {
	Name           string
	Template       string
	PathFunc       func(data *TemplateData) string
	Clear          bool
	DoNotFormat    bool
	FormatSource   bool
	RemoveNewLines bool
	PostProcessors []PostProcessor
	// TemplateFuncs template.FuncMap
	//
	tmpl       *template.Template
	moduleName string
	settings   *schema.Generator
}

// TemplateData holds template related data for processing
type TemplateData struct {
	ModuleName  string
	Schema      *schema.Schema
	Definitions []*schema.Schema
	Settings    *schema.Generator
}

var errSkip = errors.New("skip")

func configure(o *Op, req *Req, res *Res) error {
	if req == nil || req.Context == nil || req.Context.Config == nil {
		return errSkip
	}

	if !IsIn(o.Name, req.Context.Config.Generators...) {
		return errSkip
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

	settings, ok := req.Schema.Generators.Get(o.Name)
	if !ok {
		settings = schema.Generator{}
	}

	settings.SetNX("rootPathPrefix", o.Name)
	rootPathPrefix := settings.Get("rootPathPrefix").(string)
	fullPathPrefix := req.Context.Config.Target + rootPathPrefix + "/"
	settings.Set("fullPathPrefix", fullPathPrefix)

	o.settings = &settings

	tmpl := template.New("template").Funcs(TemplateFuncs)
	if _, err := tmpl.Parse(o.Template); err != nil {
		return err
	}

	o.tmpl = tmpl
	o.moduleName = strings.ToLower(req.Schema.Title)
	return nil
}

// Proces generates content for other plugins
func Proces(o *Op, req *Req, res *Res) error {
	if err := configure(o, req, res); err != nil {
		if err == errSkip {
			return nil
		}

		return err
	}

	for _, def := range SortedObjectSchemas(req.Schema.Definitions) {
		if err := execute(o, req, res, def); err != nil {
			return err
		}
	}

	return nil
}

func ProcesRoot(o *Op, req *Req, res *Res) error {
	if err := configure(o, req, res); err != nil {
		if err == errSkip {
			return nil
		}

		return err
	}

	return execute(o, req, res, req.Schema)
}

func execute(o *Op, req *Req, res *Res, def *schema.Schema) error {
	data := &TemplateData{
		ModuleName:  o.moduleName,
		Schema:      def,
		Settings:    o.settings,
		Definitions: SortedObjectSchemas(def.Definitions),
	}

	var buf bytes.Buffer

	if err := o.tmpl.Execute(&buf, data); err != nil {
		return err
	}

	var content []byte
	var err error
	if o.Clear {
		content, err = utils.Clear(buf)
		if err != nil {
			return err
		}
	} else {
		content = buf.Bytes()
	}

	if o.RemoveNewLines {
		content = utils.RemoveNewLines(content)
	}

	if o.FormatSource {
		content, err = format.Source(content)
		if err != nil {
			return err
		}
	}

	res.Output = append(res.Output, Output{
		Content:     content,
		Path:        o.PathFunc(data),
		DoNotFormat: o.DoNotFormat,
	})

	return nil
}

// ProcessSingle generates output for only one level of a schema
func ProcessSingle(o *Op, def *schema.Schema, settings schema.Generator) ([]byte, error) {
	temp := template.New("single").Funcs(TemplateFuncs)
	if _, err := temp.Parse(o.Template); err != nil {
		return nil, err
	}

	var buf bytes.Buffer

	data := struct {
		Schema     *schema.Schema
		Settings   schema.Generator
		Properties []*schema.Schema
	}{
		Schema:     def,
		Settings:   settings,
		Properties: schema.SortedSchema(def.Properties),
	}

	if err := temp.ExecuteTemplate(&buf, "single", data); err != nil {
		return nil, err
	}

	b := buf.Bytes()

	for _, processor := range o.PostProcessors {
		b = processor(b)
	}

	return b, nil
}
