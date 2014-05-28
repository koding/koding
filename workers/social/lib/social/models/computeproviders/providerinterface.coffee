
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

  @fetchAvailable = NOT_IMPLEMENTED

  @postCreate     = PASS_THROUGH

  @fetchCredentialData  = (credential, callback)->

    if not credential?.fetchData?
      return callback null, {}

    credential.fetchData (err, credData)->

      if err?
        callback new KodingError "Failed to fetch credential"
      else if credData?
        callback null, credData
      else
        callback null, {}
