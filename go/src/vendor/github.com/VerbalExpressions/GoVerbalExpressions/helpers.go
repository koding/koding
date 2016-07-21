package verbalexpressions

/* proxy and helpers to regexp.Regexp functions */

// Test return true if verbalexpressions matches something in string "s"
func (v *VerbalExpression) Test(s string) bool {
	return v.Regex().Match([]byte(s))
}

// Replace alias to regexp.ReplaceAllString. It replace the found expression from
// string src by string dst
func (v *VerbalExpression) Replace(src string, dst string) string {
	return v.Regex().ReplaceAllString(src, dst)
}

// Returns a slice of results from captures. If you didn't apply BeginCapture() and EnCapture(), the slices
// will return slice of []string where []string is length 1, and 0 index is the global capture
func (v *VerbalExpression) Captures(s string) [][]string {
	iter := 1
	if v.flags&GLOBAL != 0 {
		iter = -1
	}
	return v.Regex().FindAllStringSubmatch(s, iter)
}
