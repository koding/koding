request = require 'request'
koding = require './bongo'
KONFIG = require 'koding-config-manager'

{ redirectOauth, saveOauthToSession } = require './helpers'
{ isAddressValid, cleanUrl } = require '../../models/utils'
urljoin = require 'url-join'

provider = 'gitlab'
headers  =
  'Accept'     : 'application/json'
  'User-Agent' : 'Koding'

getPathFor = (url, path) ->
  { gitlab } = KONFIG
  port = if gitlab.port then ":#{gitlab.port}" else ''
  url ?= "#{gitlab.host}#{port}"
  urljoin url, path

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
    console.error '[GITLAB][3/4] Failed to get access_token:', error ? body
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

  { gitlab } = KONFIG
  { clientId } = req.cookies
  { state }    = req.query

  fetchGroupSettings clientId, state, (err, settings) ->

    if err or not settings
      console.error '[GITLAB][2/4] Failed to fetch group settings:', err
      return fail req, res

    { url, applicationId, applicationSecret, redirectUri } = settings

    url = cleanUrl url

    isAddressValid url, (err) ->

      if err

        if err.type is 'NOT_REACHABLE'
          console.error '[GITLAB][2/4] Provided url is not reachable:', url
          return fail req, res

        else if err.type is 'PRIVATE_IP' and not gitlab.allowPrivateOAuthEndpoints
          console.error '[GITLAB][2/4] Provided url is not allowed:', url
          return fail req, res

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
