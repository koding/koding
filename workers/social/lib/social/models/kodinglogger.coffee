{ argv }         = require 'optimist'
KONFIG           = require('koding-config-manager').load("main.#{argv.c}")

LOG_IDENTIFIER   = '[%scope%:%group%]'
SCOPES           = ['log', 'error', 'warn', 'info']

LOG_DESTINATION  = KONFIG.papertrail.destination
DEFAULT_GROUP_ID = KONFIG.papertrail.groupId
token            = KONFIG.papertrail.token

Papertrail       = new (require 'papertrail') { token }

stripcolorcodes  = require 'stripcolorcodes'
winston          = require 'winston'


module.exports = class KodingLogger

  @SCOPES = SCOPES

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


  SCOPES.forEach (scope) =>

    @[scope] = (requester, message...) =>

      group = if typeof requester is 'string'
        requester
      else if requester.context?.group?
        requester.context.group
      else
        'unknown'

      @processMessage scope, group, message...


  @connect = ->

    return @logger  if @logger

    require('winston-papertrail').Papertrail

    [host, port] = LOG_DESTINATION.split ':'
    port         = +port
    program      = 'KodingLogger'
    logFormat    = (_, message) -> message

    @pt = new winston.transports.Papertrail { host, port, logFormat, program }
    @logger = new winston.Logger { transports: [ @pt ] }


  @processMessage = (scope, group, message...) ->

    scope   = 'log' if scope not in SCOPES
    message = "#{@getIdentifier scope, group} #{message}"

    console[scope] message

    unless KONFIG.environment is 'production'
      logger = @connect()
      logger.info message


  @close = ->

    return  unless @logger

    @logger.close()
    @logger = null
    @pt     = null


  @search = (options = {}, callback = -> ) ->

    { query, from, limit } = options

    withQuery   =
      q         : query
      group_id  : DEFAULT_GROUP_ID

    withQuery.min_id = from  if from?

    Papertrail

      .searchEvents withQuery

      .then (data) ->
        setTimeout -> callback null, processData data, limit

      .catch (err) ->
        callback
          status  : 500
          message : 'The server encountered an internal error.'
          code    : 'InternalError'


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

