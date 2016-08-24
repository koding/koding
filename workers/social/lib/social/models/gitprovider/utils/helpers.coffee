http        = require 'https'
KodingError = require '../../../error'

RAW_CONTENT_TIMEOUT = 5000

module.exports = helpers =

  decodeContent: (data) ->

    return  unless data

    { content, encoding } = data

    content = new Buffer(content, encoding).toString()  if encoding

    return content


  loadRawContent: (options, callback) ->

    timeout = options.timeout ? RAW_CONTENT_TIMEOUT
    delete options.timeout

    isError = no
    r = http.request options, (response) ->
      result = ''
      response.on 'data', (chunk) -> result += chunk
      response.on 'end', -> callback null, result  unless isError
      response.on 'error', (err) ->
        isError = yes
        callback err
    r.setTimeout timeout, ->
      isError = yes
      callback new KodingError 'Request timeout'
    r.end()
