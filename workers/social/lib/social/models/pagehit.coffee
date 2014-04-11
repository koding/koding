jraphical     = require 'jraphical'
elasticsearch = require 'es'
{
  secure
  signature
  Base
}             = require 'bongo'
{argv}        = require 'optimist'
KONFIG        = require('koding-config-manager').load("main.#{argv.c}")

{
  pageHit: {
    run, host, port
  }
} = KONFIG

config = {
  server : {
    host
    port
  }
}

es = elasticsearch config

module.exports = class JPageHit extends Base
  @share()

  @set
    sharedMethods :
      static:
        create: (signature Object, Function)

  @createMapping: (callback)->
    es.indices.createIndex @indexOptions(), {
      mapping              :
        pagehits           :
          aggregates       :
            properties     :
              username     :
                type       : "string"
              path         :
                type       : "string"
              ip           :
                type       : "string"
              loggedIn     :
                type       : "boolean"
              _timestamp   :
                enabled    : true
                path       : "@timestamp"
              "@timestamp" :
                format     : "dateOptionalTime"
                type       : "date"
    }, callback

  @indexOptions:->
    rawCurr   = new Date()
    currDate  = rawCurr.getDate()
    currMonth = rawCurr.getMonth() + 1
    currYear  = rawCurr.getFullYear()

    # es wants 0 in front of single digits in index
    if currMonth < 10
      currMonth = "0#{currMonth}"

    if currDate < 10
      currDate = "0#{currDate}"

    currDate  = "#{currYear}.#{currMonth}.#{currDate}"

    gaIndexOptions = {
      _index : "pagehits-#{currDate}"
      _type  : 'events'
    }

    return gaIndexOptions

  @create: secure (client, params, callback)->
    return  callback null unless run

    {sessionToken} = client
    JSession       = require './session'
    JSession.one {clientId: sessionToken}, (err, session) =>
      return callback err  if err

      unless session
        console.error "session not found", sessionToken
        return callback {message : "session not found"}

      {clientIP}              = session
      {path, query, username} = params

      {pathname, query} = (require "url").parse path
      query             = (require "querystring").parse query

      if not /^guest-/.test username
        loggedIn = true
      else
        loggedIn = false

      record = {
        username
        query
        loggedIn
        ip           : clientIP
        path         : pathname
        "@timestamp" : new Date
      }

      documents = [ record ]

      es.bulkIndex @indexOptions(), documents, callback
