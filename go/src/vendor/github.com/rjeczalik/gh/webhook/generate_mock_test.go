package webhook

import (
	"os"
	"testing"
	"text/template"
	"unicode"
)

var fn = map[string]interface{}{"camelCase": func(s string) (t string) {
	up := true
	for _, r := range s {
		switch r {
		case '_':
			up = true
		default:
			if up {
				t = t + string(unicode.ToUpper(r))
				up = false
			} else {
				t = t + string(r)
			}
		}
	}
	return t
}}

const mock = `// Created by go generate; DO NOT EDIT

package webhook

type DetailHandler map[string]int
{{range $event, $_ := .}}
func (dh DetailHandler) {{camelCase $event}}(*{{camelCase $event}}Event) {
	dh["{{$event}}"]++
}
{{end}}
type BlanketHandler map[string]int

func (bh BlanketHandler) All(event string, _ interface{}) {
	bh[event]++
}
`

var tmplMock = template.Must(template.New("mock_test").Funcs(fn).Parse(mock))

func TestGenerateMockHelper(t *testing.T) {
	var do bool
	for args := os.Args[1:]; len(args) > 1; args = args[1:] {
		if args[0] == "--" && args[1] == "-generate" {
			do = true
			break
		}
	}
	if !do {
		t.Skip("usage: go test -run TestGenerateMockHelper -- -generate")
	}
	f, err := os.OpenFile("mock_test.go", os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		t.Fatal(err)
	}
	if err = nonil(tmplMock.Execute(f, payloads), f.Sync(), f.Close()); err != nil {
		os.Remove("mock_test.go")
		t.Fatal(err)
	}
}
