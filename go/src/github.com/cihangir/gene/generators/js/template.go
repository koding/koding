package js

// FunctionsTemplate provides the template for js clients of models
var FunctionsTemplate = `{{$schema := .Schema}}{{$title := $schema.Title}}{{$moduleName := .ModuleName}}var iz, processRequest;
iz = require('iz');
processRequest = require('./_request.js');

module.exports = (function(o) {
  return {
    {{range $funcKey, $funcValue := $schema.Functions}}
    {{$funcKey}}: function(data, callback) {
      {{GenerateJSValidator $funcValue.Properties.incoming}}
      return processRequest(o.baseUrl + '/{{ToLower $title}}/{{ToLower $funcKey}}', data, callback)
    },
    {{end}}
  }
})(o);
`
