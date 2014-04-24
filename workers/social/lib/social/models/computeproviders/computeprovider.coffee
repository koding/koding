
{Base, secure, signature} = require 'bongo'
KodingError = require '../../error'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

PROVIDERS =
  amazon       : require './amazon'
  koding       : require './koding'
  google       : require './google'
  digitalocean : require './digitalocean'

checkCredential = (cred, callback)->
  if cred is 1
  then callback null, {cred:"whoooho"}
  else callback new KodingError "Credential failed.", "AccessDenied"

module.exports = class ComputeProvider extends Base

  @share()

  # TODO Add Permissons ~ GG

  @set
    sharedMethods       :
      static            :
        ping            :
          (signature Object, Function)
        fetchExisting   :
          (signature Object, Function)
        fetchAvailables :
          (signature Object, Function)

  revive = do ->

    (fn) -> ->

      [client, options, callback] = arguments

      if typeof callback isnt 'function'
        callback = (err)-> console.error "Unhandled error:", err.message

      {provider, credential} = options

      if not provider or not provider = PROVIDERS[provider]
        return callback new KodingError "No such provider.", "ProviderNotFound"
      else
        arguments[1].provider = provider

      if not credential
        return callback new KodingError "Credential is required.", "MissingCredential"

      _arguments = arguments

      checkCredential credential, (err, cred)=>

        if err then return callback err

        _arguments[1].credential = cred

        fn.apply @, _arguments

  @ping = secure revive (client, options, callback)->

    provider.ping client, callback

  @fetchExisting = secure revive (client, options, callback)->

    {provider} = options
    provider.fetchExisting client, options, (err, instances)->
      return callback err  if err
      callback null, instances
