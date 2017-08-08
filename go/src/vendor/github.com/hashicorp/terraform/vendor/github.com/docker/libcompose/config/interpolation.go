package config

import (
	"bytes"
	"fmt"
	"strings"

	"github.com/Sirupsen/logrus"
)

func isNum(c uint8) bool {
	return c >= '0' && c <= '9'
}

func validVariableNameChar(c uint8) bool {
	return c == '_' ||
		c >= 'A' && c <= 'Z' ||
		c >= 'a' && c <= 'z' ||
		isNum(c)
}

func parseVariable(line string, pos int, mapping func(string) string) (string, int, bool) {
	var buffer bytes.Buffer

	for ; pos < len(line); pos++ {
		c := line[pos]

		switch {
		case validVariableNameChar(c):
			buffer.WriteByte(c)
		default:
			return mapping(buffer.String()), pos - 1, true
		}
	}

	return mapping(buffer.String()), pos, true
}

func parseVariableWithBraces(line string, pos int, mapping func(string) string) (string, int, bool) {
	var buffer bytes.Buffer

	for ; pos < len(line); pos++ {
		c := line[pos]

		switch {
		case c == '}':
			bufferString := buffer.String()

			if bufferString == "" {
				return "", 0, false
			}

			return mapping(buffer.String()), pos, true
		case validVariableNameChar(c):
			buffer.WriteByte(c)
		default:
			return "", 0, false
		}
	}

	return "", 0, false
}

func parseInterpolationExpression(line string, pos int, mapping func(string) string) (string, int, bool) {
	c := line[pos]

	switch {
	case c == '$':
		return "$", pos, true
	case c == '{':
		return parseVariableWithBraces(line, pos+1, mapping)
	case !isNum(c) && validVariableNameChar(c):
		// Variables can't start with a number
		return parseVariable(line, pos, mapping)
	default:
		return "", 0, false
	}
}

func parseLine(line string, mapping func(string) string) (string, bool) {
	var buffer bytes.Buffer

	for pos := 0; pos < len(line); pos++ {
		c := line[pos]
		switch {
		case c == '$':
			var replaced string
			var success bool

			replaced, pos, success = parseInterpolationExpression(line, pos+1, mapping)

			if !success {
				return "", false
			}

			buffer.WriteString(replaced)
		default:
			buffer.WriteByte(c)
		}
	}

	return buffer.String(), true
}

func parseConfig(key string, data *interface{}, mapping func(string) string) error {
	switch typedData := (*data).(type) {
	case string:
		var success bool

		*data, success = parseLine(typedData, mapping)

		if !success {
			return fmt.Errorf("Invalid interpolation format for key \"%s\": \"%s\"", key, typedData)
		}
	case []interface{}:
		for k, v := range typedData {
			err := parseConfig(key, &v, mapping)

			if err != nil {
				return err
			}

			typedData[k] = v
		}
	case map[interface{}]interface{}:
		for k, v := range typedData {
			err := parseConfig(key, &v, mapping)

			if err != nil {
				return err
			}

			typedData[k] = v
		}
	}

	return nil
}

// Interpolate replaces variables in a map entry
func Interpolate(key string, data *interface{}, environmentLookup EnvironmentLookup) error {
	return parseConfig(key, data, func(s string) string {
		values := environmentLookup.Lookup(s, nil)

		if len(values) == 0 {
			logrus.Warnf("The %s variable is not set. Substituting a blank string.", s)
			return ""
		}

		// Use first result if many are given
		value := values[0]

		// Environment variables come in key=value format
		// Return everything past first '='
		return strings.SplitN(value, "=", 2)[1]
	})
}
