class AccessError extends Error
  constructor:(@message)->

class PINExistsError extends Error
  constructor:(@message)->
    Error.call @
    @name = 'PINExistsError'
    @message = message

class KodingError extends Error
  constructor:(message)->
    return new KodingError(message) unless @ instanceof KodingError
    Error.call @
    @message = message
    @name = 'KodingError'

this.Error = KodingError