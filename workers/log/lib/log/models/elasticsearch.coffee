elasticsearch = require 'es'
UAParser      = require 'ua-parser-js'
_             = require "underscore"

require_koding_model = require '../require_koding_model'

{
  secure
  signature
  Base
} = require 'bongo'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

{
  log           : { run }
  elasticSearch : { host, port}
} = KONFIG

config = {
  server : {
    host
    port
  }
}

es = elasticsearch config

module.exports = class ElasticSearch extends Base
  @getIndexOptions: (name, type)->
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

    indexOptions = {
      _index : "#{name}-#{currDate}"
      _type  : type
    }

    return indexOptions

  @getUserInfo: (client, callback)->
    {sessionToken} = client
    JSession       = require_koding_model 'session'
    JSession.one {clientId: sessionToken}, (err, session) =>
      return callback err  if err

      unless session
        console.error "session not found", sessionToken
        return callback {message : "session not found"}

      {username, clientIP} = session

      if username and not /^guest-/.test username
        loggedIn = true
      else
        loggedIn = false

      record = {
        username
        loggedIn
        ip       : clientIP
      }

      callback null, record

  @parseUserAgent: (userAgent)->
    parser = new UAParser()
    result = parser.setUA(userAgent).getResult()

    {
      browser: {
        version : browser_version
        name    : browser_name
      }
      os: {
        version : os_version
        name    : os_name
      }
    } = result

    return {browser_version, browser_name, os_version, os_name}

  @create: (indexOptions, documents, callback)->
    return  callback null  unless run

    for doc in documents
      if userAgent = doc.userAgent
        userAgentParams = @parseUserAgent userAgent
        doc = _.extend doc, userAgentParams

      doc["@timestamp"] ?= new Date

    es.bulkIndex indexOptions, documents, callback
