request = require 'request'
koding = require './bongo'

{ failedReq, fetchUserOAuthInfo, fetchGroupOAuthSettings } = require './helpers'
urljoin = require 'url-join'

provider = 'github'
url      = 'https://github.com'
apiUrl   = 'https://api.github.com'
headers  =
  'Accept'     : 'application/json'
  'User-Agent' : 'Koding'


# Get access token with code
authorizeUser = (url, req, res) -> (error, response, body) ->

  if error or not access_token = body.access_token
    console.error '[GITHUB][3/4] Failed to get access_token:', error ? body
    return failedReq provider, req, res

  options   =
    url     : urljoin apiUrl, "/user?access_token=#{access_token}"
    method  : 'GET'
    headers :
      'Accept'     : 'application/vnd.github.v3.full+json'
      'User-Agent' : 'Koding'

  { scope } = body

  request options, fetchUserOAuthInfo provider, req, res, {
    scope, access_token
  }


module.exports = (req, res) ->

  unless code = req.query.code
    console.error '[GITHUB][1/4] Failed to get code from query:', req.query
    return failedReq provider, req, res

  { clientId } = req.cookies
  { state }    = req.query

  fetchGroupOAuthSettings provider, clientId, state, (err, settings) ->

    if err or not settings
      console.error '[GITHUB][2/4] Failed to fetch group settings:', err
      return failedReq provider, req, res

    { applicationId, applicationSecret, redirectUri } = settings

    options           =
      url             : urljoin url, '/login/oauth/access_token'
      method          : 'POST'
      headers         : headers
      json            :
        redirect_uri  : redirectUri
        grant_type    : 'authorization_code'
        client_id     : applicationId
        client_secret : applicationSecret
        code          : code

    request options, authorizeUser url, req, res
