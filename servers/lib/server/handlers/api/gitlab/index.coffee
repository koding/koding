
KONFIG    = require 'koding-config-manager'
async     = require 'async'

{ sendApiError, sendApiResponse } = require '../helpers'

apiErrors = require '../errors'

log = (rest...) -> console.log '[GitLab]', rest...

module.exports = GitLabHandler = (req, res, next) ->

  Models = (require '../../../bongo').models

  log req.body, req.headers

  sendApiResponse res, 'ok'
