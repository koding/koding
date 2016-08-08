// Package inflect provides an inflector.
package inflect

import (
	"github.com/chuckpreslar/inflect/languages"
	"github.com/chuckpreslar/inflect/types"
)

var (
	// Language to use when converting a word from it's plural to
	// singular forms and vice versa.
	Language = "en"

	// Languages avaiable for converting a word from
	// it's plural to singular forms and vice versa.
	Languages = map[string]*types.LanguageType{
		"en": languages.English,
	}
)
