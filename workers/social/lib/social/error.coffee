encoder = require 'htmlencode'

# Includes message, type pairs
KnownErrors =
  'Access denied' : 'AccessDenied'

module.exports = class KodingError extends Error

  constructor: (message, name, errorObject) ->

    return new KodingError encoder.XSSEncode message  unless this instanceof KodingError

    Error.call this

    @message = message
    @name    = name or KnownErrors[message] or 'KodingError'
    @error   = errorObject  if errorObject
