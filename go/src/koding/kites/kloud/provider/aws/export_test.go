package aws

import (
	"text/template"

	"koding/kites/kloud/stackplan"
)

// Provider exports the p for tests purposes.
func Provider() *stackplan.Provider {
	return p
}

// Bootstrap exports the bootstrap template for tests purposes.
func BootstrapTemplate() *template.Template {
	return bootstrap
}
