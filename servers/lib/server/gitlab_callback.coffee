http       = require 'http'
{ gitlab } = require 'koding-config-manager'
{ redirectOauth, saveOauthToSession } = require './helpers'

provider = 'gitlab'
headers  =
  'Accept'     : 'application/json'
  'User-Agent' : 'Koding'

# Get user info with access token
fetchUserInfo = (req, res, access_token) -> (userInfoResp) ->

  rawResp = ''
  userInfoResp.on 'data', (chunk) -> rawResp += chunk
  userInfoResp.on 'end', ->

    try
      userInfo = JSON.parse rawResp
    catch e
      return redirectOauth 'could not parse gitlab response', req, res, { provider }

    { username, id, email, name } = userInfo
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
      options = { provider, returnUrl }
      redirectOauth err, req, res, options


# Get access token with code
authorizeUser = (req, res) -> (authUserResp) ->

  rawResp = ''
  authUserResp.on 'data', (chunk) -> rawResp += chunk
  authUserResp.on 'end', ->

    try
      authResponse = JSON.parse rawResp
    catch e
      return redirectOauth 'could not parse gitlab response', req, res, { provider }

    { access_token } = authResponse

    unless access_token
      return redirectOauth 'could not get access token', req, res, { provider }

    options   =
      host    : gitlab.host ? 'gitlab.com'
      port    : gitlab.port ? 80
      path    : "/api/v3/user?access_token=#{access_token}"
      method  : 'GET'
      headers : headers

    r = http.request options, fetchUserInfo req, res, access_token
    r.end()


module.exports = (req, res) ->

  { code } = req.query

  unless code
    redirectOauth 'No code', req, res, { provider }
    return

  path = '/oauth/token?'
  path += "client_id=#{gitlab.applicationId}&"
  path += "client_secret=#{gitlab.applicationSecret}&"
  path += "code=#{code}&"
  path += 'grant_type=authorization_code&'
  path += "redirect_uri=#{gitlab.redirectUri}"

  options   =
    host    : gitlab.host ? 'gitlab.com'
    port    : gitlab.port ? 80
    path    : path
    method  : 'POST'
    headers : headers

  r = http.request options, authorizeUser req, res
  r.end()
