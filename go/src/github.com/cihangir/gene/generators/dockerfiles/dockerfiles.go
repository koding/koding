package dockerfiles

import (
	"bytes"
	"fmt"
	"text/template"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

type Generator struct {
	// CMDPath holds the path to executable files
	CMDPath string
}

// Generate generates Dockerfile for given schema
func (c *Generator) Generate(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	tmpl := template.New("dockerfile.tmpl").Funcs(context.TemplateFuncs)
	if _, err := tmpl.Parse(DockerfileTemplate); err != nil {
		return nil, err
	}

	moduleName := context.ModuleNameFunc(s.Title)
	outputs := make([]common.Output, 0)

	for _, def := range common.SortedObjectSchemas(s.Definitions) {

		var buf bytes.Buffer

		data := struct {
			CMDPath    string
			ModuleName string
			Schema     *schema.Schema
		}{
			CMDPath:    c.CMDPath,
			ModuleName: moduleName,
			Schema:     def,
		}

		if err := tmpl.Execute(&buf, data); err != nil {
			return nil, err
		}

		path := fmt.Sprintf(
			"%s/%s/Dockerfile",
			context.Config.Target,
			context.FileNameFunc(def.Title),
		)

		outputs = append(outputs, common.Output{Content: buf.Bytes(), Path: path, DoNotFormat: true})
	}

	return outputs, nil
}

// DockerfileTemplate holds the template for Dockerfile
var DockerfileTemplate = `# Start from a Debian image with the latest version of Go installed
# and a workspace (GOPATH) configured at /go.
FROM golang

# Copy the local package files to the container's workspace.
ADD . /go/src

# Build the outyet command inside the container.
# (You may fetch or manage dependencies here,
# either manually or with a tool like "godep".)

RUN go install {{.CMDPath}}{{ToLower .Schema.Title}}

# Run the outyet command by default when the container starts.
ENTRYPOINT /go/bin/{{ToLower .Schema.Title}}

# Document that the service listens on port 8080.
# EXPOSE 8080
# TODO make this configurable

# to build the docker machine
# docker build -t {{ToLower .Schema.Title}} -f {{.CMDPath}}dockerfiles/{{ToLower .Schema.Title}}/Dockerfile ./src/

# to run the built docker machine
# docker run -it {{ToLower .Schema.Title}}
`
