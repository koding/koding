{
  redirectOauth
  saveOauthToSession
}          = require './helpers'

{ github } = KONFIG
http       = require 'https'
provider   = 'github'

saveOauthAndRedirect = (resp, res, clientId, req) ->
  { returnUrl } = resp
  saveOauthToSession resp, clientId, provider, (err) ->
    options = { provider, returnUrl }
    redirectOauth err, req, res, options


fetchUserEmail = (req, res,  userEmailResp, originalResp) ->
  { clientId }  = req.cookies
  rawResp       = ''
  userEmailResp.on 'data', (chunk) -> rawResp += chunk
  userEmailResp.on 'end', ->
    try
      emails = JSON.parse(rawResp)
    catch e
      return redirectOauth 'could not parse github response', req, res, { provider }

    for email in emails when email.verified and email.primary
      originalResp.email = email.email

    saveOauthAndRedirect originalResp, res, clientId, req


module.exports = (req, res) ->
  { code, returnUrl } = req.query
  { clientId }        = req.cookies
  access_token        = null
  scope               = null

  unless code
    redirectOauth 'No code', req, res, { provider }
    return

  headers =
    'Accept'     : 'application/json'
    'User-Agent' : 'Koding'

  # Get access token with code
  authorizeUser = (authUserResp) ->
    rawResp = ''
    authUserResp.on 'data', (chunk) -> rawResp += chunk
    authUserResp.on 'end', ->

      try
        authResponse = JSON.parse rawResp
      catch e
        return redirectOauth 'could not parse github response', req, res, { provider }

      { access_token, scope } = authResponse

      if access_token
        options =
          host    : 'api.github.com'
          path    : "/user?access_token=#{access_token}"
          method  : 'GET'
          headers : headers
        r = http.request options, fetchUserInfo
        r.end()

  # Get user info with access token
  fetchUserInfo = (userInfoResp) ->
    rawResp = ''
    userInfoResp.on 'data', (chunk) -> rawResp += chunk
    userInfoResp.on 'end', ->

      try
        userInfo = JSON.parse rawResp
      catch e
        return redirectOauth 'could not parse github response', req, res, { provider }

      { login, id, email, name } = userInfo

      if name
        [firstName, restOfNames...] = name.split ' '
        lastName = restOfNames.join ' '

      resp = {
        firstName
        lastName
        email
        foreignId : String(id)
        token     : access_token
        username  : login
        profile   : lastName
        scope     : scope
        returnUrl : returnUrl
      }

      headers['Accept'] = 'application/vnd.github.v3.full+json'

      # Some users don't have email in public profile, so we make 2nd call
      # to get them.
      if not email? or email is ''
        options =
          host    : 'api.github.com'
          path    : "/user/emails?access_token=#{access_token}"
          method  : 'GET'
          headers : headers
        r = http.request options, (newResp) ->
          fetchUserEmail req, res,  newResp, resp
        r.end()
      else
        saveOauthAndRedirect resp, res, clientId, req

  path = '/login/oauth/access_token?'
  path += "client_id=#{github.clientId}&"
  path += "client_secret=#{github.clientSecret}&"
  path += "code=#{code}"

  options =
    host   : 'github.com'
    path   : path
    method : 'POST'
    headers : headers
  r = http.request options, authorizeUser
  r.end()


