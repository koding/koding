package template

import (
	"fmt"
	"testing"

	r "github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

var testProviders = map[string]terraform.ResourceProvider{
	"template": Provider(),
}

func TestTemplateRendering(t *testing.T) {
	var cases = []struct {
		vars     string
		template string
		want     string
	}{
		{`{}`, `ABC`, `ABC`},
		{`{a="foo"}`, `${a}`, `foo`},
		{`{a="hello"}`, `${replace(a, "ello", "i")}`, `hi`},
		{`{}`, `${1+2+3}`, `6`},
	}

	for _, tt := range cases {
		r.Test(t, r.TestCase{
			PreCheck: func() {
				readfile = func(string) ([]byte, error) {
					return []byte(tt.template), nil
				}
			},
			Providers: testProviders,
			Steps: []r.TestStep{
				r.TestStep{
					Config: testTemplateConfig(tt.vars),
					Check: func(s *terraform.State) error {
						got := s.RootModule().Outputs["rendered"]
						if tt.want != got {
							return fmt.Errorf("template:\n%s\nvars:\n%s\ngot:\n%s\nwant:\n%s\n", tt.template, tt.vars, got, tt.want)
						}
						return nil
					},
				},
			},
		})
	}
}

// https://github.com/hashicorp/terraform/issues/2344
func TestTemplateVariableChange(t *testing.T) {
	steps := []struct {
		vars     string
		template string
		want     string
	}{
		{`{a="foo"}`, `${a}`, `foo`},
		{`{b="bar"}`, `${b}`, `bar`},
	}

	var testSteps []r.TestStep
	for i, step := range steps {
		testSteps = append(testSteps, r.TestStep{
			PreConfig: func(template string) func() {
				return func() {
					readfile = func(string) ([]byte, error) {
						return []byte(template), nil
					}
				}
			}(step.template),
			Config: testTemplateConfig(step.vars),
			Check: func(i int, want string) r.TestCheckFunc {
				return func(s *terraform.State) error {
					got := s.RootModule().Outputs["rendered"]
					if want != got {
						return fmt.Errorf("[%d] got:\n%q\nwant:\n%q\n", i, got, want)
					}
					return nil
				}
			}(i, step.want),
		})
	}

	r.Test(t, r.TestCase{
		Providers: testProviders,
		Steps:     testSteps,
	})
}

func testTemplateConfig(vars string) string {
	return `
resource "template_file" "t0" {
	filename = "mock"
	vars = ` + vars + `
}
output "rendered" {
    value = "${template_file.t0.rendered}"
}
	`
}
