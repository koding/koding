request = require 'request'
koding  = require './bongo'

{ gitlab, hostname } = require 'koding-config-manager'
{ redirectOauth, saveOauthToSession } = require './helpers'

provider = 'gitlab'
headers  =
  'Accept'     : 'application/json'
  'User-Agent' : 'Koding'


fetchGroupSettings = (clientId, callback) ->

  { JSession, JGroup } = koding.models

  JSession.one { clientId }, (err, session) ->
    return callback err  if err
    return callback { message: 'Session invalid' }  unless session

    { groupName: slug } = session

    JGroup.one { slug }, (err, group) ->
      return callback err  if err
      return callback { message: 'Group invalid' }  unless group

      if not group.config?.gitlab? or not group.config.gitlab.enabled
        return callback { message: 'Integration not enabled yet.' }

      group.fetchDataAt 'gitlab', (err, data) ->
        return callback err  if err
        return callback { message: 'Integration settings invalid' }  unless data

        callback null, {
          url: group.config.gitlab.url
          applicationId: group.config.gitlab.applicationId
          applicationSecret: data.applicationSecret
          redirectUri: "http://#{slug}.#{hostname}/-/oauth/#{provider}/callback"
        }


getPathFor = (url, path) ->
  url ?= "http://#{gitlab.host ? 'gitlab.com'}:#{gitlab.port ? 80}"
  "#{url}#{path}"

fail = (req, res) ->
  redirectOauth 'could not grant access', req, res, { provider }

# Get user info with access token
fetchUserInfo = (req, res, access_token) -> (error, response, body) ->

  if error or not id = body.id
    console.error '[GITLAB][4/4] Failed to fetch user info:', error
    return fail req, res

  { username, id, email, name } = body
  { returnUrl } = req.query
  { clientId }  = req.cookies

  if name
    [firstName, restOfNames...] = name.split ' '
    lastName = restOfNames.join ' '

  resp = {
    email
    lastName
    username
    firstName
    token     : access_token
    profile   : lastName
    foreignId : String(id)
    returnUrl : returnUrl
  }

  saveOauthToSession resp, clientId, provider, (err) ->
    redirectOauth err, req, res, { provider, returnUrl }


# Get access token with code
authorizeUser = (url, req, res) -> (error, response, body) ->

  if error or not access_token = body.access_token
    console.error '[GITLAB][3/4] Failed to get access_token:', error
    return fail req, res

  options   =
    url     : getPathFor url, '/api/v3/user'
    method  : 'GET'
    headers : headers
    json    : { access_token }

  request options, fetchUserInfo req, res, access_token


module.exports = (req, res) ->

  unless code = req.query.code
    console.error '[GITLAB][1/4] Failed to get code from query:', req.query
    return fail req, res

  { clientId } = req.cookies

  fetchGroupSettings clientId, (err, settings) ->

    if err or not settings
      console.error '[GITLAB][2/4] Failed to fetch group settings:', err
      return fail req, res

    { url, applicationId, applicationSecret, redirectUri } = settings

    options           =
      url             : getPathFor url, '/oauth/token'
      method          : 'POST'
      headers         : headers
      json            :
        redirect_uri  : redirectUri
        grant_type    : 'authorization_code'
        client_id     : applicationId
        client_secret : applicationSecret
        code          : code

    request options, authorizeUser url, req, res
