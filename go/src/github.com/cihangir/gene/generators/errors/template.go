package errors

// ErrorsTemplate holds the template for the errors package
var ErrorsTemplate = `
package errs
var (
{{$moduleName := ToUpperFirst .Schema.Title}}
{{range $key, $value := .Schema.Properties}}
    Err{{$moduleName}}{{DepunctWithInitialUpper $key}}NotSet = errors.New("{{$moduleName}}.{{DepunctWithInitialUpper $key}} not set")
{{end}}
)
`
