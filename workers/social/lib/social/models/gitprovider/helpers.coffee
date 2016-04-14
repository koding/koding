http = require 'https'

module.exports = helpers =

  decodeContent: (data) ->

    return  unless data

    { content, encoding } = data

    return new Buffer(content, encoding).toString()  if encoding
    return content


  loadRawContent: (options, callback) ->

    r = http.request options, (response) ->
      result = ''
      response.on 'data', (chunk) -> result += chunk
      response.on 'end', -> callback result
    r.end()
