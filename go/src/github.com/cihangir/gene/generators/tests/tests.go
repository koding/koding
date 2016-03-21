// Package tests creates tests files for the given schema
package tests

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

type generator struct{}

func New() *generator {
	return &generator{}
}

var PathForTests = "%smodels/%s_statements.go"

func (g *generator) Name() string {
	return "statements"
}

// Generate generates the tests for the schema
func (g *generator) Generate(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	moduleName := context.ModuleNameFunc(s.Title)
	outputs := make([]common.Output, 0)

	// Generate test functions
	testFuncs, err := GenerateTestFuncs(s)
	if err != nil {
		return nil, err
	}

	path := fmt.Sprintf("%stests/testfuncs.go", context.Config.Target)

	outputs = append(outputs, common.Output{
		Content: testFuncs,
		Path:    path,
	})

	// generate module test file
	mainTest, err := GenerateMainTestFileForModule(s)
	if err != nil {
		return nil, err
	}

	path = fmt.Sprintf(
		"%sworkers/%s/tests/common_test.go",
		context.Config.Target,
		moduleName,
	)

	outputs = append(outputs, common.Output{
		Content: mainTest,
		Path:    path,
	})

	// generate tests for the schema
	for _, def := range s.Definitions {
		testFile, err := GenerateTests(s.Title, def)
		if err != nil {
			return nil, err
		}
		path = fmt.Sprintf(
			"%sworkers/%s/tests/%s_test.go",
			context.Config.Target,
			moduleName,
			strings.ToLower(def.Title),
		)

		outputs = append(outputs, common.Output{
			Content: testFile,
			Path:    path,
		})

	}

	return outputs, nil
}

// GenerateMainTestFileForModule generates the main test file for the module
// which will be used by other test files
func GenerateMainTestFileForModule(s *schema.Schema) ([]byte, error) {
	// TODO check if file is there, no need to continue
	temp := template.New("mainTestFile.tmpl").Funcs(common.TemplateFuncs)

	if _, err := temp.Parse(MainTestsTemplate); err != nil {
		return nil, err
	}

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "mainTestFile.tmpl", data); err != nil {
		return nil, err
	}

	return format.Source(buf.Bytes())
}

// GenerateTestFuncs generates tests functions
func GenerateTestFuncs(s *schema.Schema) ([]byte, error) {
	// TODO check if file is there, no need to continue
	temp := template.New("testFuncs.tmpl")
	if _, err := temp.Parse(TestFuncs); err != nil {
		return nil, err
	}

	data := struct {
		Schema *schema.Schema
	}{
		Schema: s,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "testFuncs.tmpl", data); err != nil {
		return nil, err
	}

	return format.Source(buf.Bytes())
}

// GenerateTests generates the actual tests for the schema
func GenerateTests(moduleName string, s *schema.Schema) ([]byte, error) {
	temp := template.New("tests.tmpl").Funcs(common.TemplateFuncs)

	if _, err := temp.Parse(TestsTemplate); err != nil {
		return nil, err
	}

	data := struct {
		ModuleName string
		Schema     *schema.Schema
	}{
		ModuleName: strings.ToLower(moduleName),
		Schema:     s,
	}

	var buf bytes.Buffer

	if err := temp.ExecuteTemplate(&buf, "tests.tmpl", data); err != nil {
		return nil, err
	}
	return format.Source(buf.Bytes())
}
