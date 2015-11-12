package main

import (
	"reflect"
	"strconv"
	"strings"
)

type Matcher struct {
	Collection []interface{}
	NotMatched map[int]bool

	filters []func(item interface{}) bool
}

func NewMatcher(items []interface{}) *Matcher {
	notmatched := make(map[int]bool)
	matcher := &Matcher{
		Collection: items,
		NotMatched: notmatched,
	}
	return matcher
}

func (matcher *Matcher) ByInt(base, modified string) *Matcher {
	modifiedInt, _ := strconv.Atoi(modified)

	if modifiedInt == 0 {
		return matcher
	}

	filter := func(item interface{}) bool {
		v := reflect.ValueOf(item)
		field := v.FieldByName(base)

		if !field.IsValid() {
			log.Info("There is no field with name %s", base)
		}
		return matchInt(int(field.Int()), modifiedInt)
	}

	matcher.addFilter(filter)
	return matcher
}

func (matcher *Matcher) ByString(base, modified string) *Matcher {
	if modified == "" {
		return matcher
	}

	filter := func(item interface{}) bool {
		v := reflect.ValueOf(item)
		field := v.FieldByName(base)

		if !field.IsValid() {
			log.Info("There is no field with name %s", base)
		}
		return matchString(field.String(), modified)
	}

	matcher.addFilter(filter)
	return matcher
}

func (matcher *Matcher) Run() []interface{} {
	for _, filter := range matcher.filters {
		for i, item := range matcher.Collection {
			if !filter(item) {
				if !matcher.NotMatched[i] {
					matcher.NotMatched[i] = true
				}
			}
		}
	}

	// Return filtred matched items
	p := make([]interface{}, 0)
	for index, item := range matcher.Collection {
		if !matcher.NotMatched[index] {
			p = append(p, item)
		}
	}

	return p
}

func (matcher *Matcher) addFilter(filter func(interface{}) bool) {
	matcher.filters = append(matcher.filters, filter)
}

func matchString(a, b string) bool {
	ok := strings.ToLower(a) == strings.ToLower(b)
	return ok
}

func matchInt(a, b int) bool {
	ok := a == b
	return ok
}
