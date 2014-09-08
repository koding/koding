package multiconfig

import "github.com/fatih/structs"

// TagLoader satisfies the loader interface. It parses a struct's field tags
// and populated the each field with that given tag.
type TagLoader struct {
	// DefaultTagName is the default tag name for struct fields to define
	// default values for a field. Example:
	//
	//   // Field's default value is "koding".
	//   Name string `default:"koding"`
	//
	// The default value is "default" if it's not set explicitly.
	DefaultTagName string
}

func (t *TagLoader) Load(s interface{}) error {
	if t.DefaultTagName == "" {
		t.DefaultTagName = "default"
	}

	for _, field := range structs.Fields(s) {
		defaultVal := field.Tag(t.DefaultTagName)
		if defaultVal == "" {
			continue
		}

		err := fieldSet(field, defaultVal)
		if err != nil {
			return err
		}
	}

	return nil
}
