
{ fetchSession }    = require '../../helpers'

{ sendApiError,
  sendApiResponse } = require './helpers'
errors              = require './errors'


class KodingLogger


  GROUP_IDENTIFIER = '([log:%group%] OR [error:%group%] OR [warning:%group%])'
  DEFAULT_GROUP_ID = 867873 # koding.com group ID in papertrail
  Papertrail       = new (require 'papertrail') token: '4p4KML0UeU4ijb0swx'
  stripcolorcodes  = require 'stripcolorcodes'

  processData = (data, limit = 100) ->

    processedData = {
      from : data.min_id
      to   : data.max_id
      logs : []
    }

    for log in data.events[...limit]
      message = stripcolorcodes log.message
      processedData.logs.push message

    return processedData


  @search = (options = {}, callback = ->) ->

    { query, from, limit } = options

    withQuery   =
      q         : query
    # group_id  : DEFAULT_GROUP_ID

    withQuery.min_id = from  if from?

    Papertrail

      .searchEvents withQuery

      .then (data) ->
        callback null, processData data, limit

      .catch (err) ->
        callback errors.internalError


  @generateRestrictedQuery = (group, query, scope) ->

    group = GROUP_IDENTIFIER.replace /%group%/g, group
    query = if query then "#{query} AND #{group}" else group

    return query


module.exports = (req, res, next) ->

  fetchSession req, res, (err, session) ->

    if err or not session
      return sendApiError res, errors.unauthorizedRequest

    # safe zone

    { q, limit, from, scope } = req.query

    query = KodingLogger.generateRestrictedQuery 'gokmen', q, scope

    KodingLogger.search { query, limit, from }, (err, logs) ->

      if err
      then sendApiError    res, err
      else sendApiResponse res, logs
