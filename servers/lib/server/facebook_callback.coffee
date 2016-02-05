{
  redirectOauth
  saveOauthToSession
}            = require './helpers'
{ facebook } = KONFIG
http         = require 'https'
{ decode }   = require 'querystring'
provider     = 'facebook'

module.exports = (req, res) ->
  access_token = null
  { clientId } = req.cookies
  { code }     = req.query

  unless code
    redirectOauth 'No code', req, res, { provider }
    return

  url  = 'https://graph.facebook.com/oauth/access_token?'
  url += "client_id=#{facebook.clientId}&"
  url += "redirect_uri=#{facebook.redirectUri}&"
  url += "client_secret=#{facebook.clientSecret}&"
  url += "code=#{code}&"
  url += 'scope=email'

  # Get access token with code
  http.get url, (httpResp) ->
    rawResp = ''
    httpResp.on 'data', (chunk) -> rawResp += chunk
    httpResp.on 'end', ->
      access_token = decode(rawResp).access_token
      if access_token
        options =
          host    : 'graph.facebook.com'
          path    : "/me?access_token=#{access_token}"
          method  : 'GET'
        r = http.request options, fetchUserInfo
        r.end()
      else
        console.log 'facebook err, no access token', rawResp
        redirectOauth 'No access token', req, res, { provider }

  # Get user info with access token
  fetchUserInfo = (userInfoResp) ->
    rawResp = ''
    userInfoResp.on 'data', (chunk) -> rawResp += chunk
    userInfoResp.on 'end', ->
      try userInfo = JSON.parse rawResp
      catch e
        return redirectToOauth 'Failed to parse user info', req, res, { provider }

      unless userInfo?.name
        return redirectToOauth 'No user name', req, res, { provider }

      [firstName, restOfNames...] = userInfo.name.split ' '
      lastName = restOfNames.join ' '

      { username, email } = userInfo
      facebookResp = {
        username
        email
        firstName
        lastName
        token     : access_token
        foreignId : userInfo.id
      }

      saveOauthToSession facebookResp, clientId, provider, (err) ->
        if err
          console.log 'facebook err, saving to session', err
          redirectOauth err, req, res, { provider }
          return

        redirectOauth null, req, res, { provider }
