request    = require 'request'
{ gitlab } = require 'koding-config-manager'
{ redirectOauth, saveOauthToSession } = require './helpers'

provider = 'gitlab'
headers  =
  'Accept'     : 'application/json'
  'User-Agent' : 'Koding'

getUrlFor = (path) ->
  "http://#{gitlab.host ? 'gitlab.com'}:#{gitlab.port ? 80}#{path}"

fail = (req, res) ->
  redirectOauth 'could not get access token', req, res, { provider }

# Get user info with access token
fetchUserInfo = (req, res, access_token) -> (error, response, body) ->

  if error or not id = body.id
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
authorizeUser = (req, res) -> (error, response, body) ->

  if error or not access_token = body.access_token
    return fail req, res

  options   =
    url     : getUrlFor '/api/v3/user'
    method  : 'GET'
    headers : headers
    json    : { access_token }

  request options, fetchUserInfo req, res, access_token


module.exports = (req, res) ->

  return fail req, res  unless code = req.query.code

  options           =
    url             : getUrlFor '/oauth/token'
    method          : 'POST'
    headers         : headers
    json            :
      redirect_uri  : gitlab.redirectUri
      grant_type    : 'authorization_code'
      client_id     : gitlab.applicationId
      client_secret : gitlab.applicationSecret
      code          : code

  request options, authorizeUser req, res
