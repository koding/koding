package models

// PackageTemplate holds the template for the packages of the models
var PackageTemplate = `// Generated struct for {{.Schema.Title}}.
package models
`

// StructTemplate holds the template for the structs of the models
var StructTemplate = `
{{AsComment .Schema.Description}}
type {{ToUpperFirst .Schema.Title}} {{goType .Schema}}
`
