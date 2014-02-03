{
  renderOauthPopup
  saveOauthToSession
}        = require './helpers'

{github} = KONFIG
http     = require "https"
provider = "github"

saveOauthAndRenderPopup = (resp, res, clientId)->
  saveOauthToSession resp, clientId, provider, ->
    renderOauthPopup res, {error:null, provider}

module.exports = (req, res) ->
  {code}        = req.query
  {clientId}    = req.cookies
  access_token  = null

  unless code
    renderOauthPopup res, {error:"No code", provider}
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
      userInfo                 = JSON.parse rawResp
      {login, id, email, name} = userInfo
      if name
        [firstName, restOfNames...] = name.split ' '
        lastName = restOfNames.join ' '

      resp = {firstName, lastName, email}
      resp["foreignId"] = String(id)
      resp["token"]     = access_token
      resp["username"]  = login
      resp["profile"]   = userInfo

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
        saveOauthAndRenderPopup resp, res, clientId

  fetchUserEmail = (userEmailResp, originalResp)->
    rawResp = ""
    userEmailResp.on "data", (chunk) -> rawResp += chunk
    userEmailResp.on "end", ->
      emails = JSON.parse(rawResp)
      for email in emails when email.verified and email.primary
        originalResp.email = email.email

      saveOauthAndRenderPopup originalResp, res, clientId

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
