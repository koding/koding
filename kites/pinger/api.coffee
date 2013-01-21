Kite = require 'kite'
request = require 'request'
crypto = require 'crypto'
hat = require 'hat'

config = require './config'
# TODO: this is a temporary measure until we get real API keys.
secret = '8daafc24b27ab396d32751f6a8cf2964'

intervals = {}

module.exports = new Kite 'pinger'

  ping:({kiteName, uri}, callback=->)->
    request.get {
      uri
      qs            :
        data        : JSON.stringify {
          kiteName
          method      : '_ping'
          withArgs  : {kiteName}
        }
    }, (err, res, body)=>
      if err
        @stopPinging {uri}, callback
        # TODO: this is the callback to the api server:
        apiUri = config.apiUri + '/kite/disconnect'
        token = crypto.createHash('sha1')
          .update(uri+secret)
          .digest('hex')
        request.get {
          uri: apiUri
          qs: {kiteName, uri, token}
        }, -> callback()
      else
        console.log "#{kiteName} has responded to ping"
        callback()
  
  startPinging:({kiteName, uri, interval}, callback=->)->
    @stopPinging {uri}, =>
      intervals[uri] = setInterval =>
        @ping {
          kiteName
          uri
        }
      , interval
  
  stopPinging:({uri}, callback=->)->
    intervalId = intervals[uri]
    clearInterval intervalId if intervalId?
    delete intervals[uri]
    callback()