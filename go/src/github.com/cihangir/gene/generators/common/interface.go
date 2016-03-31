package common

import "github.com/cihangir/schema"

type Generator interface {
	Generate(*Context, *schema.Schema) ([]Output, error)
}
