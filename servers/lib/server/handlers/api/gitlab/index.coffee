
KONFIG    = require 'koding-config-manager'
async     = require 'async'

{ log, parseEvent, validateRequest } = require './utils'
{ sendApiError, sendApiResponse } = require '../helpers'

apiErrors = require '../errors'

HANDLERS  =
  key     : require './key'
  tag     : require './tag'
  user    : require './user'
  push    : require './push'
  group   : require './group'
  project : require './project'

module.exports = GitLabHandler = (req, res, next) ->

  return next()  unless KONFIG.gitlab.hooksEnabled

  Models = (require '../../../bongo').models

  if not event = validateRequest req
    return sendApiError res, 'not valid'

  { scope, method } = parseEvent event

  if not handler = HANDLERS[scope]
    return sendApiError res, 'not valid'

  log "Processing #{method} on #{scope}..."

  handler[method] req.body, (err, data) ->
    if err
      log 'ERROR', err
      sendApiError res, err
    else
      sendApiResponse res, data
