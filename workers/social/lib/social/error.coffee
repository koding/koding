# Includes message, type pairs
KnownErrors =
  'Access denied' : 'AccessDenied'

module.exports = class KodingError extends Error

  constructor:(message, name)->

    return new KodingError message  unless this instanceof KodingError

    Error.call this

    @message = message
    @name    = name or KnownErrors[message] or 'KodingError'
