
NOT_IMPLEMENTED = ->

  KodingError   = require '../../error'
  message       = "Not implemented yet."

  if arguments.length > 0 and fn = arguments[arguments.length - 1]
    if typeof fn is 'function' then fn new KodingError message, "NotImplemented"

  return message

PASS_THROUGH = (..., callback)-> callback null

module.exports = class ProviderInterface

  @ping           = NOT_IMPLEMENTED
  @create         = NOT_IMPLEMENTED
  @remove         = NOT_IMPLEMENTED
  @update         = NOT_IMPLEMENTED

  @fetchExisting  = NOT_IMPLEMENTED
  @fetchAvailable = NOT_IMPLEMENTED

  @postCreate     = PASS_THROUGH
