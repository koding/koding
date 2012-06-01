{ErrorResponse} = require('./error_response')

class Gateway
  createResponseHandler: (attributeName, klass, callback) ->
    (err, response) ->
      return callback(err, response) if err

      if (response[attributeName])
        response.success = true
        response[attributeName] = new klass(response[attributeName])
        callback(null, response)
      else if (response.apiErrorResponse)
        callback(null, new ErrorResponse(response.apiErrorResponse))

exports.Gateway = Gateway
