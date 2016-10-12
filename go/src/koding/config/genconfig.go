// +build ignore

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"
	"text/template"
)

var (
	input  = flag.String("i", "-", "")
	output = flag.String("o", "-", "")
)

var t = template.Must(template.New("").Parse(`// This file is auto-generated. DO NOT EDIT!

package config

import (
	"text/template"

	"github.com/koding/logging"
)

var DefaultConfig = &Config{
	Environment: defaultAliases.Get("{{.Environment}}", "development"),
	Log:         logging.NewLogger("config"),
	Host2ip:     map[string]string {
{{range $host, $ip := .Routes}}		"{{$host}}": "{{$ip}}",
{{end}}	},

	tmpls: map[string]*template.Template {
{{range $name, $t := .Templaters}}		{{($t.MapElem $name)}}
{{end}}	},
}
{{range $name, $t := .Templaters}}{{($t.Function $name)}}
{{($t.MustFunction $name)}}
{{end}}
`))

func main() {
	flag.Parse()

	fname := os.Getenv("KODING_JSON_CONFIG_FILE")
	if *input != "-" && *input != "" {
		fname = *input
	}

	if fname == "" {
		log.Fatal("input JSON file was not provided")
	}

	data, err := ioutil.ReadFile(fname)
	if err != nil {
		log.Fatal(err)
	}

	var cfg = struct {
		GoGenerate config `json:"goGenerate"`
	}{}

	if err := json.Unmarshal(data, &cfg); err != nil {
		log.Fatal(err)
	}

	buf := &bytes.Buffer{}
	if err := t.Execute(buf, cfg.GoGenerate.TemplateData()); err != nil {
		log.Fatal(err)
	}

	w := os.Stdout
	if *output != "-" && *output != "" {
		f, err := os.Create(*output)
		if err != nil {
			log.Fatal(err)
		}
		w = f
	}
	defer w.Close()

	if _, err := buf.WriteTo(w); err != nil {
		log.Fatal(err)
	}
}

type templater interface {
	MapElem(typeName string) string
	Function(typeName string) string
	MustFunction(typeName string) string
}

type config struct {
	Environment string              `json:"environment"`
	Buckets     map[string]bucket   `json:"buckets"`
	Endpoints   map[string]endpoint `json:"endpoints"`
	Routes      map[string]string   `json:"routes"`
}

func (c *config) TemplateData() interface{} {
	var td = &struct {
		Environment string
		Templaters  map[string]templater
		Routes      map[string]string
	}{
		Environment: c.Environment,
		Templaters:  make(map[string]templater),
		Routes:      c.Routes,
	}

	for name, b := range c.Buckets {
		td.Templaters["buckets."+name] = b
	}

	for name, e := range c.Endpoints {
		td.Templaters["endpoints."+name] = e
	}

	return td
}

type bucket struct {
	Name   string `json:"name"`
	Region string `json:"region"`
}

func (b bucket) MapElem(typeName string) string {
	return mapElem(typeName, b)
}

func (b bucket) Function(typeName string) string {
	return function(typeName, "*Bucket", "GetBucket")
}

func (b bucket) MustFunction(typeName string) string {
	return mustFunction(typeName, "*Bucket")
}

type endpoint string

func (e endpoint) MapElem(typeName string) string {
	return mapElem(typeName, e)
}

func (e endpoint) Function(typeName string) string {
	return function(typeName, "string", "GetEndpoint")
}

func (e endpoint) MustFunction(typeName string) string {
	return mustFunction(typeName, "string")
}

const mapElemFmt = "`%[1]s`: template.Must(template.New(`%[1]s`).Parse(`%[2]s`)),"

func mapElem(typeName string, data interface{}) string {
	b, err := json.Marshal(data)
	if err != nil {
		log.Fatalf("cannot marshal %s: %v (data:%v)", typeName, err, data)
	}

	return fmt.Sprintf(mapElemFmt, typeName, string(b))
}

const functionFmt = `
// %[1]s returns %[2]s stored in %[3]s variable.
func (c *Config) %[1]s(env string) (%[4]s, error) {
	return c.%[5]s("%[2]ss.%[3]s", c.GetEnvironment(env))
}

// %[1]s returns %[2]s stored in %[3]s variable.
//
// %[1]s is a wrapper around DefaultConfig.%[1]s.
func %[1]s(env string) (%[4]s, error) {
	return DefaultConfig.%[1]s(env)
}`

func function(typename, retType, getFuncName string) string {
	var (
		typ      = typename[:strings.IndexRune(typename, '.')-1]
		name     = typename[strings.IndexRune(typename, '.')+1:]
		funcName = functionName(typename)
	)
	return fmt.Sprintf(functionFmt, funcName, typ, name, retType, getFuncName)
}

const mustFunctionFmt = `
// Must%[1]s returns %[2]s stored in %[3]s variable. It panics in case of error.
func (c *Config) Must%[1]s(environment string) %[4]s {
	val, err := c.%[1]s(environment)
	if err != nil {
		panic(err)
	}

	return val
}

// Must%[1]s returns %[2]s stored in %[3]s variable.
//
// Must%[1]s is a wrapper around DefaultConfig.Must%[1]s.
func Must%[1]s(env string) %[4]s {
	return DefaultConfig.Must%[1]s(env)
}`

func mustFunction(typename, retType string) string {
	var (
		typ      = typename[:strings.IndexRune(typename, '.')-1]
		name     = typename[strings.IndexRune(typename, '.')+1:]
		funcName = functionName(typename)
	)
	return fmt.Sprintf(mustFunctionFmt, funcName, typ, name, retType)
}

var field2suffix = map[string]string{
	"buckets":   "Bucket",
	"endpoints": "URL",
	"routes":    "Route",
}

func functionName(typeName string) string {
	toks := strings.Split(typeName, ".")
	if len(toks) < 2 {
		log.Fatalf("invalid type name value: %s", typeName)
	}

	return strings.Title(toks[1]) + field2suffix[toks[0]]
}
