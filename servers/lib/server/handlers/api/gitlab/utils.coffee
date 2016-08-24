KONFIG = require 'koding-config-manager'

utils = {}

utils.GITLAB_TOKEN = String(KONFIG.gitlab.systemHookToken)

utils.log = (rest...) -> console.log '[GitLab]', rest...

utils.parseEvent = (event) ->

  [ scope, method... ] = event.split '_'
  method = method.join '_'
  method = 'main'  if method is ''

  return { scope, method }

utils.validateRequest = (req) ->

  token = req.headers['x-gitlab-token']
  event = req.body['event_name']

  return no  unless token or event
  return no  unless token is utils.GITLAB_TOKEN

  return event


module.exports = utils
