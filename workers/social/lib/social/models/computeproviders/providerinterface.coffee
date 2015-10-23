NOT_IMPLEMENTED_MESSAGE = 'Not implemented yet.'

NOT_IMPLEMENTED = ->

  KodingError   = require '../../error'

  if arguments.length > 0 and fn = arguments[arguments.length - 1]
    if typeof fn is 'function'
      fn new KodingError NOT_IMPLEMENTED_MESSAGE, 'NotImplemented'

  return NOT_IMPLEMENTED_MESSAGE

PASS_THROUGH = (..., callback) -> callback null

module.exports = class ProviderInterface

  @notImplementedMessage = NOT_IMPLEMENTED_MESSAGE

  @providerSlug   = 'baseprovider'
  @bootstrapKeys  = []
  @sensitiveKeys  = []

  @ping           = NOT_IMPLEMENTED

  @create         = NOT_IMPLEMENTED
  @remove         = NOT_IMPLEMENTED
  @update         = NOT_IMPLEMENTED

  @fetchAvailable = NOT_IMPLEMENTED

  @postCreate     = PASS_THROUGH

  @fetchCredentialData  = (credential, callback) ->

    if not credential?.fetchData?
      return callback null, {}

    credential.fetchData (err, credData) ->

      if err?
        callback new KodingError 'Failed to fetch credential'
      else if credData?
        callback null, credData
      else
        callback null, {}


