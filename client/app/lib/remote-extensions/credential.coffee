debug = (require 'debug') 'remote:api:jcredential'
remote = require('../remote')


module.exports = class JCredential extends remote.api.JCredential


  @some$ = (selector, options, callback) ->

    debug 'some$ called', selector, options
    JCredential.some selector, options, (err, res) ->
      debug 'some$ returned', err, res
      callback err, res


  @create = (data, callback) ->

    super data, (err, credential) ->

      if err
        console.warn 'Failed to save credential:', err
        sendDataDogEvent = require 'app/util/sendDataDogEvent'
        sendDataDogEvent 'ApplicationError', { prefix: 'app-error' }

      callback err, credential
