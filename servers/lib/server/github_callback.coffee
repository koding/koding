{
  redirectOauth
  saveOauthToSession
}        = require './helpers'

{github} = KONFIG
http     = require "https"
provider = "github"

saveOauthAndRedirect = (resp, res, clientId)->
  saveOauthToSession resp, clientId, provider, (err)->
    redirectOauth res, provider, err

module.exports = (req, res) ->
  {code}        = req.query
  {clientId}    = req.cookies
  access_token  = null

  unless code
    redirectOauth res, provider, "No code"
    return

  headers =
    "Accept"     : "application/json"
    "User-Agent" : "Koding"

  # Get access token with code
  authorizeUser = (authUserResp)->
    rawResp = ""
    authUserResp.on "data", (chunk) -> rawResp += chunk
    authUserResp.on "end", ->
      {access_token} = JSON.parse rawResp
      if access_token
        options =
          host    : "api.github.com"
          path    : "/user?access_token=#{access_token}"
          method  : "GET"
          headers : headers
        r = http.request options, fetchUserInfo
        r.end()

  # Get user info with access token
  fetchUserInfo = (userInfoResp) ->
    rawResp = ""
    userInfoResp.on "data", (chunk) -> rawResp += chunk
    userInfoResp.on "end", ->
      userInfo = JSON.parse rawResp
      {login, id, email, name} = userInfo

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
      }

      headers["Accept"] = "application/vnd.github.v3.full+json"

      # Some users don't have email in public profile, so we make 2nd call
      # to get them.
      if not email? or email is ""
        options =
          host    : "api.github.com"
          path    : "/user/emails?access_token=#{access_token}"
          method  : "GET"
          headers : headers
        r = http.request options, (newResp)-> fetchUserEmail newResp, resp
        r.end()
      else
        saveOauthAndRedirect resp, res, clientId

  fetchUserEmail = (userEmailResp, originalResp)->
    rawResp = ""
    userEmailResp.on "data", (chunk) -> rawResp += chunk
    userEmailResp.on "end", ->
      emails = JSON.parse(rawResp)
      for email in emails when email.verified and email.primary
        originalResp.email = email.email

      saveOauthAndRedirect originalResp, res, clientId

  path = "/login/oauth/access_token?"
  path += "client_id=#{github.clientId}&"
  path += "client_secret=#{github.clientSecret}&"
  path += "code=#{code}"

  options =
    host   : "github.com"
    path   : path
    method : "POST"
    headers : headers
  r = http.request options, authorizeUser
  r.end()
