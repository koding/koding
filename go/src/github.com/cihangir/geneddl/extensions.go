package geneddl

import (
	"bytes"
	"fmt"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// DefineExtensions creates definition for extensions
func DefineExtensions(settings schema.Generator, s *schema.Schema) ([]byte, error) {
	exts := make([]string, 0)

	for _, val := range s.Properties {
		if val.Default == nil {
			continue
		}

		def := fmt.Sprintf("%v", val.Default)
		switch def {
		// only uuid-ossp is supported for now
		case "uuid_generate_v1()", "uuid_generate_v1mc()", "uuid_generate_v4()":
			exts = append(exts, "uuid-ossp")
		}
	}

	if len(exts) == 0 {
		return nil, nil
	}

	temp := template.New("create_extensions.tmpl").Funcs(common.TemplateFuncs)
	if _, err := temp.Parse(ExtensionsTemplate); err != nil {
		return nil, err
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "create_extensions.tmpl", exts); err != nil {
		return nil, err
	}

	return clean(buf.Bytes()), nil
}

// ExtensionsTemplate holds template for db extensions
var ExtensionsTemplate = `
-- ----------------------------
--  Required extensions
-- ----------------------------
{{range $key, $value := .}}
CREATE EXTENSION IF NOT EXISTS "{{$value}}";
{{end}}
`
