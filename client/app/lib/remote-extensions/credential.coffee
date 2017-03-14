debug = (require 'debug') 'remote:api:jcredential'
remote = require('../remote')


module.exports = class JCredential extends remote.api.JCredential


  @some$ = (selector, options, callback) ->

    console.warn 'JCredential.some$ will be deprecated!'
    JCredential.some selector, options, callback


  @create = (data, callback) ->

    super data, (err, credential) ->

      if err
        console.warn 'Failed to save credential:', err
        sendDataDogEvent = require 'app/util/sendDataDogEvent'
        sendDataDogEvent 'ApplicationError', { prefix: 'app-error' }

      callback err, credential


  @one = ->
    console.warn 'JCredential.one will be deprecated!'
    super
