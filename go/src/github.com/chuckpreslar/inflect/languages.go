package inflect

import (
  "github.com/chuckpreslar/inflect/languages"
  "github.com/chuckpreslar/inflect/types"
)

var (
  // LANGUAGE to use when converting a word from it's plural to
  // singular forms and vice versa.
  LANGUAGE = "en"
  // LANGUAGES avaiable for converting a word from
  // it's plural to singular forms and vice versa.
  LANGUAGES = map[string]*types.LanguageType{
    "en": languages.English,
  }
)
