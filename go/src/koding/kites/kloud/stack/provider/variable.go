package provider

import (
	"bufio"
	"bytes"
	"fmt"
	"strings"
)

// Variable represents a Terraform variable
// position in a raw string.
type Variable struct {
	Name string
	From int
	To   int
}

var _ fmt.Stringer = (*Variable)(nil)

// String implements the fmt.Stringer interface.
func (v *Variable) String() string {
	return "${var." + v.Name + "}"
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
	return ReplaceVariablesFunc(s, vars, func(*Variable) string { return blank })
}

// ReplaceVariablesFunc replaces all variables with the result of fn function.
func ReplaceVariablesFunc(s string, vars []Variable, fn func(*Variable) string) string {
	var buf bytes.Buffer
	var last int

	for _, v := range vars {
		buf.WriteString(s[last:v.From])
		buf.WriteString(fn(&v))

		last = v.To
	}

	buf.WriteString(s[last:])

	return buf.String()
}

var escape = func(v *Variable) string {
	return "$" + v.String()
}

// EscapeDeadVariables escapes variables which are commented out.
//
// The comment format is hardcoded to work for Bash-like shells.
func EscapeDeadVariables(userdata string) string {
	var buf bytes.Buffer

	scanner := bufio.NewScanner(strings.NewReader(userdata))

	for scanner.Scan() {
		s := scanner.Text()

		isComment := strings.HasPrefix(strings.TrimSpace(s), "#")

		if !isComment {
			fmt.Fprintln(&buf, s)
			continue
		}

		fmt.Fprintln(&buf, ReplaceVariablesFunc(s, ReadVariables(s), escape))
	}

	return buf.String()
}
