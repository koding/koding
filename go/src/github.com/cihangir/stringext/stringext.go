// Package stringext adds extra power to the strings package with helper
// functions
package stringext

import (
	"bytes"
	"fmt"
	"regexp"
	"strings"
	"unicode"
	"unicode/utf8"
)

var (
	specialCases = regexp.MustCompile(`(?m)[-.$/:_{}\s]`)
	acronyms     = regexp.MustCompile(`(Url|Http|Id|Io|Uuid|Api|Uri|Ssl|Cname|Oauth|Otp)$`)
	acronymsi    = regexp.MustCompile(`(URL|HTTP|ID|IO|UUID|API|URI|SSL|CNAME|OAUTH|OTP)`)
)

// ToLowerFirst lowers the first character of any given unicode char
func ToLowerFirst(ident string) string {
	r, n := utf8.DecodeRuneInString(ident)
	return string(unicode.ToLower(r)) + ident[n:]
}

// ToUpperFirst converts the first character of any given unicode char to
// uppercase
func ToUpperFirst(ident string) string {
	r, n := utf8.DecodeRuneInString(ident)
	return string(unicode.ToUpper(r)) + ident[n:]
}

// Pointerize returns the first character of a given string as lowercased, this
// method is intened to use as a function receiver generator
func Pointerize(ident string) string {
	r, _ := utf8.DecodeRuneInString(ident)
	return string(unicode.ToLower(r))
}

// Capitalize uppercases the first char of s and lowercases the rest.
func Capitalize(str string) string {
	buf := &bytes.Buffer{}
	var r0 rune
	var size int

	r0, size = utf8.DecodeRuneInString(str)
	str = str[size:]
	buf.WriteRune(unicode.ToUpper(r0))

	for len(str) > 0 {
		r0, size = utf8.DecodeRuneInString(str)
		str = str[size:]
		buf.WriteRune(unicode.ToLower(r0))
	}

	return buf.String()
}

// JSONTag generates json tag for given string, it is using the javascript
// concepts
//
// eg: ID ->
// 	becomes "id" if it is at the beginning
//  	or
//  becomes "Id" if it is in the middle of the string
func JSONTag(n string, required bool) string {
	modified := ToLowerFirst(Normalize(n))

	tags := []string{modified}
	if !required {
		tags = append(tags, "omitempty")
	}

	return fmt.Sprintf("`json:\"%s\"`", strings.Join(tags, ","))
}

func JSONTagWithIgnored(n string, required bool, ignored bool, fieldType string, forceTags string) string {
	if forceTags != "" {
		return fmt.Sprintf("`%s`", forceTags)
	}

	modified := ToLowerFirst(Normalize(n))

	tags := []string{modified}
	if !required {
		tags = append(tags, "omitempty")
	}

	switch fieldType {
	case "int64", "float64", "uint64":
		tags = append(tags, "string")
	}

	// if this field is ingored, override all other tags
	if ignored {
		tags = []string{"-"}
	}

	return fmt.Sprintf("`json:\"%s\"`", strings.Join(tags, ","))
}

// Normalize removes non a-z characters and uppercases the following character,
// all characters followed by it will be lowercased if the word is one the
// acronymsi
func Normalize(s string) string {
	return acronymsi.ReplaceAllStringFunc(
		DepunctWithInitialLower(s), func(c string) string {
			return ToUpperFirst(strings.ToLower(c))
		})
}

// ToFieldName handles field names, if the given string is one of the
// `acronymsi` it is lowercasing it
//
// given "URL" as parameter converted to "url"
// given "ProfileURL" as parameter converted to "profile_url"
// given "Profile" as parameter converted to "profile"
// given "ProfileName" as parameter converted to "profile_name"
//
func ToFieldName(u string) string {
	buf := bytes.NewBufferString("")
	for i, v := range Normalize(u) {
		if i > 0 && v >= 'A' && v <= 'Z' {
			buf.WriteRune('_')
		}
		buf.WriteRune(v)
	}

	return strings.ToLower(buf.String())
}

// DepunctWithInitialUpper does special operations to the given string, while
// operating uppercases the special words
func DepunctWithInitialUpper(ident string) string {
	return Depunct(ident, true)
}

// DepunctWithInitialLower does special operations to the given string, while
// operating lowercases the special words
func DepunctWithInitialLower(ident string) string {
	return Depunct(ident, false)
}

// Depunct splits the given string with special chars and operates on them one
// by one
func Depunct(ident string, initialCap bool) string {
	matches := specialCases.Split(ident, -1)
	for i, m := range matches {
		if initialCap || i > 0 {
			m = ToUpperFirst(m)
		}
		matches[i] = acronyms.ReplaceAllStringFunc(m, func(c string) string {
			if len(c) > 4 {
				return strings.ToUpper(c[:2]) + c[2:]
			}
			return strings.ToUpper(c)
		})
	}
	return strings.Join(matches, "")
}

// Equal check if given two strings are same, used in templates
func Equal(a, b string) bool {
	return a == b
}

// AsComment formats the given string as if it is a Go Comment, breaks lines
// every 78 lines
func AsComment(c string) string {
	var buf bytes.Buffer
	const maxLen = 78
	removeNewlines := func(s string) string {
		return strings.Replace(s, "\n", "\n// ", -1)
	}
	for len(c) > 0 {
		line := c
		if len(line) < maxLen {
			fmt.Fprintf(&buf, "// %s\n", removeNewlines(line))
			break
		}
		line = line[:maxLen]
		si := strings.LastIndex(line, " ")
		if si != -1 {
			line = line[:si]
		}
		fmt.Fprintf(&buf, "// %s\n", removeNewlines(line))
		c = c[len(line):]
		if si != -1 {
			c = c[1:]
		}
	}

	return buf.String()
}

// Contains checks if the given string is in given string slice
func Contains(n string, r []string) bool {
	for _, s := range r {
		if s == n {
			return true
		}
	}

	return false
}
