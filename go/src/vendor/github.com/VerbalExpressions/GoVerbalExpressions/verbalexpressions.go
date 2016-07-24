// Copyright 2013 Patrice FERLET
// Use of this source code is governed by MIT-style
// license that can be found in the LICENSE file
package verbalexpressions

import (
	"fmt"
	"log"
	"regexp"
	"strconv"
	"strings"
)

type Flag uint

const (
	MULTILINE Flag = 1 << iota
	IGNORE_CASE
	DOTALL
	UNGREEDY
	GLOBAL
)

// VerbalExpression structure to create expression
type VerbalExpression struct {
	expression string
	parts      []string
	suffixes   string
	prefixes   string
	flags      Flag
	compiled   bool
	regexp     *regexp.Regexp
}

// quote is an alias to regexp.QuoteMeta
func quote(s string) string {
	return regexp.QuoteMeta(s)
}

// utility function to return only strings
func tostring(i interface{}) string {
	var r string
	switch x := i.(type) {
	case string:
		r = x
	case uint64:
		r = strconv.FormatUint(x, 10)
	case int64:
		r = strconv.FormatInt(x, 10)
	case uint:
		r = strconv.FormatUint(uint64(x), 10)
	case int:
		r = strconv.FormatInt(int64(x), 10)
	default:
		log.Panicf("Could not convert %v %t", x, x)
	}
	return r
}

// Instanciate a new VerbalExpression. You should use this method to
// initalize some internal var.
//
// Example:
//		v := verbalexpression.New().Find("foo")
func New() *VerbalExpression {
	r := new(VerbalExpression)
	r.flags = MULTILINE | GLOBAL
	r.parts = make([]string, 0)
	return r
}

// append a modifier
func (v *VerbalExpression) addmodifier(f Flag) *VerbalExpression {
	v.compiled = false //reinit previous regexp compilation
	v.flags |= f
	return v
}

// remove a modifier
func (v *VerbalExpression) removemodifier(f Flag) *VerbalExpression {
	v.compiled = false //reinit previous regexp compilation
	v.flags &= ^f
	return v
}

// append modifiers that are activated
func (v *VerbalExpression) getFlags() string {
	flags := "misU" // warning, follow Flag const order
	result := []rune{}

	for i, flag := range flags {
		if v.flags&(1<<uint(i)) != 0 {
			result = append(result, flag)
		}
	}

	return string(result)
}

// add method, append expresions to the internal string that will be parsed
func (v *VerbalExpression) add(s string) *VerbalExpression {
	v.compiled = false //reinit previous regexp compilation
	v.expression += s
	return v
}

// Start to capture something, stop with EndCapture()
func (v *VerbalExpression) BeginCapture() *VerbalExpression {
	v.suffixes += ")"
	return v.add("(")
}

// Stop capturing expresions parts
func (v *VerbalExpression) EndCapture() *VerbalExpression {
	v.suffixes = strings.Replace(v.suffixes, ")", "", 1)
	return v.add(")")
}

// Anything will match any char
func (v *VerbalExpression) Anything() *VerbalExpression {
	return v.add(`(?:.*)`)
}

// AnythingBut will match anything excpeting the given string.
func (v *VerbalExpression) AnythingBut(s string) *VerbalExpression {
	return v.add(`(?:[^` + quote(s) + `]*)`)
}

// Something matches at least one char
func (v *VerbalExpression) Something() *VerbalExpression {
	return v.add(`(?:.+)`)
}

// Same as Something but excepting chars given in string "s"
func (v *VerbalExpression) SomethingBut(s string) *VerbalExpression {
	return v.add(`(?:[^` + quote(s) + `]+)`)
}

// EndOfLine tells verbalexpressions to match a end of line.
// Warning, to check multiple line, you must use SearchOneLine(true)
func (v *VerbalExpression) EndOfLine() *VerbalExpression {
	if !strings.HasSuffix(v.suffixes, "$") {
		v.suffixes += "$"
	}
	return v
}

// Maybe will search string zero on more times
func (v *VerbalExpression) Maybe(s string) *VerbalExpression {
	return v.add(`(?:` + quote(s) + `)?`)
}

// StartOfLine seeks the begining of a line. As EndOfLine you should use
// SearchOneLine(true) to test multiple lines
func (v *VerbalExpression) StartOfLine() *VerbalExpression {
	if !strings.HasPrefix(v.prefixes, "^") {
		v.prefixes = `^` + v.prefixes
	}
	return v
}

// Find seeks string. The string MUST be there (unlike Maybe() method)
func (v *VerbalExpression) Find(s string) *VerbalExpression {
	return v.add(`(?:` + quote(s) + `)`)
}

// Not invert Find, meaning search something excepting "value". This
// is different than SomethingBut or AnythingBut that works with a list of
// caracters. Note that this method is not exactly the same as PCRE system.
//
// While PCRE allows: foo(?!bar)baz, "foobarrbaz" matches (note the double r).
// With our method, this doesn't match. But: "foobarbaz" doen't match (so it's ok).
// And "fooXXXbaz" matches also.
func (v *VerbalExpression) Not(value string) *VerbalExpression {
	//return v.add(`(?!(` + quote(value) + `))`)
	// because Golang doesn't implement ?!
	// we create a pseudo negative system...

	runes := []rune(quote(value))
	parts := make([]string, 0)
	prev := ""
	for _, r := range runes {
		parts = append(parts, prev+"[^"+string(r)+"]")
		prev += string(r)
	}

	exp := strings.Join(parts, "|")
	exp = "(?:" + exp + ")*?"
	return v.add(exp)
}

// Alias to Find()
func (v *VerbalExpression) Then(s string) *VerbalExpression {
	return v.Find(s)
}

// Any accepts caracters to be matched
func (v *VerbalExpression) Any(s string) *VerbalExpression {
	return v.add(`(?:[` + quote(s) + `])`)
}

//AnyOf is an alias to Any
func (v *VerbalExpression) AnyOf(s string) *VerbalExpression {
	return v.Any(s)
}

// LineBreak to find "\n" or "\r\n"
func (v *VerbalExpression) LineBreak() *VerbalExpression {
	return v.add(`(?:(?:\n)|(?:\r\n))`)
}

// Alias to LineBreak
func (v *VerbalExpression) Br() *VerbalExpression {
	return v.LineBreak()
}

// Range accepts an even number of arguments. Each pair of values defines start and end of range.
// Think like this: Range(from, to [, from, to ...])
func (v *VerbalExpression) Range(args ...interface{}) *VerbalExpression {
	if len(args)%2 != 0 {
		log.Panicf("Range: not even args number")
	}

	parts := make([]string, 3)
	app := ""
	for i := 0; i < len(args); i++ {
		app += tostring(args[i])
		if i%2 != 0 {
			parts = append(parts, quote(app))
			app = ""
		} else {
			app += "-"
		}
	}
	return v.add("[" + strings.Join(parts, "") + "]")
}

// Tab fetch tabulation char (\t)
func (v *VerbalExpression) Tab() *VerbalExpression {
	return v.add(`\t+`)
}

// Word matches any word (containing alpha char)
func (v *VerbalExpression) Word() *VerbalExpression {
	return v.add(`\w+`)
}

// Multiply string s expression
//
// Multiple(value string [, min int[, max int]])
//
// This method accepts 1 to 3 arguments, argument 2 is min, argument 3 is max:
//
//		// get "foo" at least one time
//		v.Multiple("foo")
//		v.Multiple("foo", 1)
//
//		// get "foo" 0 or more times
//		v.Multiple("foo", 0)
//
//		//get "foo" 0 or 1 times
//		v.Multiple("foo", 0, 1)
//
//		// get "foo" 0 to 10 times
//		v.Multiple("foo",0 ,10)
//
//		//get "foo" at least 10 times
//		v.Multiple("foo", 10)
//
//		//get "foo" exactly 10 times
//		v.Multiple("foo", 10, 10)
//
//		//get "foo" from 1 to 10 times
//		v.Multiple("foo", 1, 10)
func (v *VerbalExpression) Multiple(s string, mults ...int) *VerbalExpression {

	if len(mults) > 2 {
		panic("Multiple: you can only give 1 or to multipliers, min and max as int")
	}
	// fetch multiplier if any
	var min, max int = -1, -1
	mult := "+"

	if len(mults) > 0 {
		min = mults[0]
		if len(mults) == 2 {
			max = mults[1]
		}
	}

	if min == 0 && max == 1 {
		// 0 or 1 time
		mult = "?"
	}

	if min == 0 && max == -1 {
		// 0 or more
		mult = "*"
	}

	if min == 1 && max == -1 {
		// at least 1 time
		mult = "+"
	}

	if min > 1 && max == -1 {
		//at least min times
		mult = fmt.Sprintf("{%d,}", min)
	}

	if max > 1 {
		if min > 0 {
			// min to max times
			mult = fmt.Sprintf("{%d,%d}", min, max)
		} else {
			// max times
			mult = fmt.Sprintf("{,%d}", max)
		}
	}

	return v.add("(?:" + quote(s) + ")" + mult)
}

// Or, chains an alternative VerbalExpression
func (v *VerbalExpression) Or(ve *VerbalExpression) *VerbalExpression {
	v.parts = append(v.parts, ve.Regex().String()+"|")
	return v
}

// Add another VerbalExpression to the current.
// Usefull to concatenate several complex search patterns
func (v *VerbalExpression) And(ve *VerbalExpression) *VerbalExpression {
	return v.add("(?:" + ve.Regex().String() + ")")
}

// WithAnyCase asks verbalexpressions to match with or without case sensitivity
func (v *VerbalExpression) WithAnyCase(sensitive bool) *VerbalExpression {
	if sensitive {
		return v.addmodifier(IGNORE_CASE)
	}
	return v.removemodifier(IGNORE_CASE)
}

// SearchOneLine deactivates "multiline" mode if online argument is true
// Default is false
func (v *VerbalExpression) SearchOneLine(oneline bool) *VerbalExpression {
	if !oneline {
		return v.addmodifier(MULTILINE)
	}
	return v.removemodifier(MULTILINE)
}

// MatchAllWithDot lets VerbalExpression matching "." for everything including \n, \r, and so on
func (v *VerbalExpression) MatchAllWithDot(enable bool) *VerbalExpression {
	if enable {
		return v.addmodifier(DOTALL)
	}
	return v.removemodifier(DOTALL)
}

// Regex returns the regular expression to use to test on string.
func (v *VerbalExpression) Regex() *regexp.Regexp {

	if !v.compiled {
		v.regexp = regexp.MustCompile(
			strings.Join([]string{
				strings.Join(v.parts, ""),
				`(?` + v.getFlags() + `)`,
				v.prefixes,
				v.expression,
				v.suffixes}, ""))
		v.compiled = true
	}
	return v.regexp
}

func (v *VerbalExpression) StopAtFirst(enable bool) *VerbalExpression {
	if enable {
		return v.removemodifier(GLOBAL)
	}

	return v.addmodifier(GLOBAL)
}

/*
Already implemented => v

v	add
v	startOfLine
v	endOfLine
v	then
v	find
v	maybe
v	anything
v	anythingBut
v	something
v	somethingBut
v	replace
v	lineBreak
v	br (shorthand for lineBreak)
v	tab
v	word
v	anyOf
v	any (shorthand for anyOf)
v	range
v	withAnyCase
v	stopAtFirst
v	searchOneLine
v	multiple
v	or
v	begindCapture
v	endCapture
*/
