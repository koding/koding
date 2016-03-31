package common

import (
	"fmt"
	"path/filepath"
	"reflect"
	"runtime"
	"testing"

	"github.com/cihangir/schema"
)

// IsIn checks if the first param is in the following ones
func IsIn(s string, ts ...string) bool {
	for _, t := range ts {
		if t == s {
			return true
		}
	}

	return false
}

func SortedObjectSchemas(m map[string]*schema.Schema) []*schema.Schema {
	objectSchemas := make([]*schema.Schema, 0)
	for _, def := range schema.SortedSchema(m) {
		if def.Type != nil {
			if t, ok := def.Type.(string); ok {
				if t == "object" {
					objectSchemas = append(objectSchemas, def)
				}
			}
		}
	}

	return objectSchemas
}

func TestEquals(tb testing.TB, exp, act interface{}) {
	if !reflect.DeepEqual(exp, act) {
		_, file, line, _ := runtime.Caller(1)
		fmt.Printf("\033[31m%s:%d:\n\n\texp: %#v\n\n\tgot: %#v\033[39m\n\n", filepath.Base(file), line, exp, act)
		tb.Fail()
	}
}
