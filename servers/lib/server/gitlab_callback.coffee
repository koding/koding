request = require 'request'
koding = require './bongo'
KONFIG = require 'koding-config-manager'

{ failedReq, fetchUserOAuthInfo, fetchGroupOAuthSettings } = require './helpers'
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

# Get access token with code
authorizeUser = (url, req, res) -> (error, response, body) ->

  if error or not access_token = body.access_token
    console.error '[GITLAB][3/4] Failed to get access_token:', error ? body
    return failedReq provider, req, res

  options   =
    url     : getPathFor url, '/api/v3/user'
    method  : 'GET'
    headers : headers
    json    : { access_token }

  { scope } = body

  request options, fetchUserOAuthInfo provider, req, res, {
    access_token, scope
  }


module.exports = (req, res) ->

  unless code = req.query.code
    console.error '[GITLAB][1/4] Failed to get code from query:', req.query
    return failedReq provider, req, res

  { gitlab }   = KONFIG
  { clientId } = req.cookies
  { state }    = req.query

  fetchGroupOAuthSettings provider, clientId, state, (err, settings) ->

    if err or not settings
      console.error '[GITLAB][2/4] Failed to fetch group settings:', err
      return failedReq provider, req, res

    { url, applicationId, applicationSecret, redirectUri } = settings

    url = cleanUrl url

    isAddressValid url, (err) ->

      if err

        if err.type is 'NOT_REACHABLE'
          console.error '[GITLAB][2/4] Provided url is not reachable:', url
          return failedReq provider, req, res

        else if err.type is 'PRIVATE_IP' and not gitlab.allowPrivateOAuthEndpoints
          console.error '[GITLAB][2/4] Provided url is not allowed:', url
          return failedReq provider, req, res

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
