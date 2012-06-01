class AccessError extends Error
  constructor:(@message)->

class KodingError extends Error
  constructor:(message)->
    return new KodingError(message) unless @ instanceof KodingError
    Error.call @
    @message = message
    @name = 'KodingError'

this.Error = KodingError