debug = (require 'debug') 'remote:jcredential'
remote = require('../remote')

module.exports = class JCredential extends remote.api.JCredential


  @some$ = (selector, options, callback) ->

    debug 'some$ called', selector, options
    JCredential.some selector, options, (err, res) ->
      debug 'some$ returned', err, res
      callback err, res
