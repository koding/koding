package google

import "text/template"

// Bootstrap exports the bootstrap template for tests purposes.
func BootstrapTemplate() *template.Template {
	return bootstrap
}
