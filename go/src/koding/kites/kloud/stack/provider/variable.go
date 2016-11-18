package provider

import (
	"bytes"
	"strings"
)

// Variable represents a Terraform variable
// position in a raw string.
type Variable struct {
	Name string
	From int
	To   int
}

// ReadVariables gives a list of variables read from s.
func ReadVariables(s string) []Variable {
	if strings.Count(s, "${") == 0 {
		return nil
	}

	var vars []Variable
	var i int

	for i < len(s) {
		j := strings.Index(s[i:], "${")
		if j == -1 {
			break
		}

		i += j + 2

		k := strings.IndexRune(s[i:], '}')
		if k == -1 {
			break
		}

		name := strings.TrimSpace(s[i : i+k])

		if !strings.HasPrefix(name, "var.") {
			continue
		}

		vars = append(vars, Variable{
			Name: name[4:],
			From: i - 2,
			To:   i + k + 1,
		})
	}

	return vars
}

// ReplaceVariables replaces all variables with the given blank.
func ReplaceVariables(s string, vars []Variable, blank string) string {
	var buf bytes.Buffer
	var last int

	for _, v := range vars {
		buf.WriteString(s[last:v.From])
		buf.WriteString(blank)

		last = v.To
	}

	buf.WriteString(s[last:])

	return buf.String()
}
