package aws

import (
	"text/template"

	"koding/kites/kloud/stack/provider"
)

// Provider exports the p for tests purposes.
func Provider() *provider.Provider {
	return p
}

// Bootstrap exports the bootstrap template for tests purposes.
func BootstrapTemplate() *template.Template {
	return bootstrap
}
