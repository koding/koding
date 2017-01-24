{ clone } = require 'underscore'
{ updateMachine } = require './helpers'
KodingError = require '../../error'

clientRequire = require '../../clientrequire'
replaceUserInputs = clientRequire 'app/lib/util/stacks/replaceuserinputs'

NOT_IMPLEMENTED_MESSAGE = 'Not implemented yet.'

NOT_IMPLEMENTED = ->

  if arguments.length > 0 and fn = arguments[arguments.length - 1]
    if typeof fn is 'function'
      fn new KodingError NOT_IMPLEMENTED_MESSAGE, 'NotImplemented'

  return NOT_IMPLEMENTED_MESSAGE

PASS_THROUGH = (rest... , callback) -> callback null

# Base class for all providers
#
# @example How to subclass a provider
#   class Aws extends ProviderInterface
#
#     @providerSlug = 'aws'
#     @bootstrapKeys = ['key_pair', 'rtb', 'acl']
#     @secretKeys = ['access_key', 'secret_key']
#
module.exports = class ProviderInterface

  @notImplementedMessage = NOT_IMPLEMENTED_MESSAGE

  @providerSlug   = 'baseprovider'
  @bootstrapKeys  = []
  @sensitiveKeys  = ['ssh_private_key', 'ssh_public_key']
  @secretKeys     = []

  @ping           = NOT_IMPLEMENTED

  @create         = NOT_IMPLEMENTED
  @remove         = NOT_IMPLEMENTED
  @update         = NOT_IMPLEMENTED

  @fetchAvailable = NOT_IMPLEMENTED

  @supportsStacks = yes
  @postCreate     = PASS_THROUGH

  @_requireTemplate = ->
    @template = clientRequire \
      "app/lib/providers/templates/#{@providerSlug}.coffee"
    @templateWithDefaults = replaceUserInputs clone @template

  # Generic fetcher for JCredential's data on this provider
  #
  # @param [Object] client valid client object
  # @param [Object] credential valid JCredential instance
  # @param [Function] callback function
  # @return [Boolean, Object] credential data
  #
  @fetchCredentialData = (client, credential, callback) ->

    if not credential?.fetchData?
      return callback null, {}

    credential.fetchData client, {}, (err, credData) ->

      if err?
        callback new KodingError 'Failed to fetch credential'
      else if credData?
        callback null, credData
      else
        callback null, {}


  # Generic modifier for JMachine's on this provider
  #
  # @param [Object] valid client object
  # @param [Object] options for update
  # @option options [String] machineId target JMachine._id
  # @option options [Boolean] alwaysOn always on state of the machine
  # @return [Boolean, Object] modified JMachine instance
  #
  @update = (client, options, callback) ->

    { machineId, alwaysOn } = options
    { r: { group, user, account } } = client

    unless machineId? or alwaysOn?
      return callback new KodingError \
        'A valid machineId and an update option required.', 'WrongParameter'

    JMachine = require './machine'
    selector = JMachine.getSelectorFor client, { machineId, owner: yes }
    selector.provider = @providerSlug

    updateMachine { selector, alwaysOn }, callback
