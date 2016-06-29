
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

  Models = (require '../../../bongo').models


  sendApiResponse res, 'ok'
