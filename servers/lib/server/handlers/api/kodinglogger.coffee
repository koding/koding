errors           = require './errors'

LOG_IDENTIFIER   = '[%scope%:%group%]'
SCOPES           = ['log', 'error', 'warn', 'info']

LOG_DESTINATION  = 'logs3.papertrailapp.com:13734'
                 # 'logs.papertrailapp.com:49069' # PRODUCTION
DEFAULT_GROUP_ID = 2199093 # log test group ID in papertrail
                 # 867873  # koding.com group ID in papertrail

stripcolorcodes  = require 'stripcolorcodes'
Papertrail       = new (require 'papertrail') token: '4p4KML0UeU4ijb0swx'
winston          = require 'winston'

module.exports = class KodingLogger


  @send = (scope, group, log) ->

    scope   = 'log' if scope not in SCOPES
    message = "#{getIdentifier scope, group} #{log}"
    logger  = @getLogger()

    logger.info    message
    console[scope] message


  @getLogger = ->

    return @logger  if @logger

    require('winston-papertrail').Papertrail

    [host, port] = LOG_DESTINATION.split ':'
    port         = +port
    program      = 'KodingLogger'
    logFormat    = (_, message) -> message
    @logger      = new winston.Logger
      transports: [new winston.transports.Papertrail {
        host, port, logFormat, program
      }]


  @destroyLogger = ->

    return  unless @logger

    @logger.close()
    @logger = null


  processData = (data, limit = 100) ->

    processedData = {
      from : data.min_id
      to   : data.max_id
      logs : []
    }

    for log in data.events[...limit]
      message = (stripcolorcodes log.message).trim()
      processedData.logs.push {
        message, id: log.id, createdAt: log.generated_at
      }

    return processedData


  getScopes = (scope) ->

    return SCOPES  if not scope or scope.trim?() is ''

    scopes = scope.split ','
      .map    (x) -> x.trim()
      .filter (x) -> x in SCOPES

    scopes = SCOPES  if scopes.length is 0

    return scopes


  getIdentifier = (scope, group) ->

    scope = LOG_IDENTIFIER.replace /%scope%/, scope
    return scope.replace /%group%/, group


  @search = (options = {}, callback = ->) ->

    { query, from, limit } = options

    withQuery   =
      q         : query
      group_id  : DEFAULT_GROUP_ID

    withQuery.min_id = from  if from?

    Papertrail

      .searchEvents withQuery

      .then (data) ->
        callback null, processData data, limit

      .catch (err) ->
        callback errors.internalError


  @generateRestrictedQuery = (group, query, scope) ->

    scopes = getScopes scope

    if scopes.length is 1
      restriction = getIdentifier scopes[0], group
    else
      restrictions = []
      for scope in scopes
        restrictions.push getIdentifier scope, group
      restriction = "(#{restrictions.join ' OR '})"

    query = if query then "#{restriction} AND #{query}" else restriction

    return query
