package aws

import "html/template"

// Bootstrap exports the bootstrap template for tests purposes.
func Bootstrap() *template.Template {
	return bootstrap
}
