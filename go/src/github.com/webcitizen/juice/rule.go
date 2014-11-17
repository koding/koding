package juice

import (
	"strings"
)

type Rules []Rule

type Rule struct {
	Selector   string
	Properties []Property
}

func (r Rule) Style() string {
	buf := make([]string, 0)
	for _, property := range r.Properties {
		buf = append(buf, property.String())
	}
	return strings.Join(buf, " ")
}
