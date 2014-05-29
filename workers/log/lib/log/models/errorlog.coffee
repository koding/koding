ElasticSearch = require "./elasticsearch"
_             = require "underscore"
checksum      = require "checksum"

{
  secure
  signature
} = require 'bongo'

uniqInt = 15

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

      _.extend record, params

      rawCurr = new Date

      year    = rawCurr.getFullYear()
      month   = rawCurr.getMonth() + 1
      date    = rawCurr.getDate()
      hour    = rawCurr.getHours()
      min     = Math.round(rawCurr.getMinutes() / uniqInt) * uniqInt # round to nearest time

      timeStr = "#{year}#{month}#{date}#{hour}#{min}"

      {error:err, reason} = params
      {username} = record

      # to reduce noise in logs, we don't log if there was the same error from
      # same user within `uniqInt`; es enforces unique constraint on `_id`
      idStr = "#{err}#{reason}#{username}#{timeStr}"
      _id   = checksum idStr

      # _.extends modifies source object, so we clone to keep them seperate
      cloneRecord = _.clone record
      _.extend cloneRecord, {_id, uniqueInterval: uniqInt}

      documents  = [ cloneRecord, record ]

      ElasticSearch.create @errorsIndex(), documents, callback
