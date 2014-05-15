ElasticSearch = require "./elasticsearch"
_             = require "underscore"
checksum      = require "checksum"

{
  secure
  signature
} = require 'bongo'

uniqInt = 2

module.exports = class JErrorLog extends ElasticSearch
  @share()

  @set
    sharedMethods :
      static:
        create: (signature Object, Function)

  @errorsIndex:->
    @getIndexOptions("errorlogs", "errors")

  @create: secure (client, params, callback)->
    @getUserInfo client, (err, record)=>
      return callback err  if err

      rawCurr   = new Date
      date  = rawCurr.getDate()
      month = rawCurr.getMonth() + 1
      year  = rawCurr.getFullYear()
      hour  = rawCurr.getHours()
      min   = Math.round(rawCurr.getMinutes()/uniqInt)*uniqInt

      _.extend record, params

      {error, reason} = params
      {username} = record

      timeStr    = "#{error}#{reason}#{username}#{year}#{month}#{date}#{hour}#{min}"
      _id        = checksum timeStr

      # _.extends modifies source object, so we clone to keep them seperate
      cloneRecord = _.clone record
      _.extend cloneRecord, {_id, uniqueInterval: uniqInt}

      documents  = [ cloneRecord, record ]

      ElasticSearch.create @errorsIndex(), documents, callback
