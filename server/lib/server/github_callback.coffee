{
  saveOauthToSession
  renderOauthPopup
}        = require './helpers'

{github} = KONFIG
http     = require "https"

saveOauthAndRenderPopup = (resp, res)->
  saveOauthToSession resp, ->
    renderOauthPopup res, {error:null, provider:"github"}

module.exports = (req, res) ->
  {provider}    = req.params
  {code}        = req.query
  access_token  = null

  unless code
    renderOauthPopup res, {error:{message:"No code"}, provider:"github"}
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
      {login, id, email, name} = JSON.parse rawResp
      if name
        [firstName, restOfNames...] = name.split ' '
        lastName = restOfNames.join ' '

      {clientId} = req.cookies
      resp = {provider, firstName, lastName, login, id, email, access_token,
              clientId}

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
        saveOauthAndRenderPopup resp, res

  fetchUserEmail = (userEmailResp, originalResp)->
    rawResp = ""
    userEmailResp.on "data", (chunk) -> rawResp += chunk
    userEmailResp.on "end", ->
      email = JSON.parse(rawResp)[0]
      originalResp.email = email

      saveOauthAndRenderPopup originalResp, res

  options =
    host   : "github.com"
    path   : "/login/oauth/access_token?client_id=#{github.clientId}&client_secret=#{github.clientSecret}&code=#{code}"
    method : "POST"
    headers : headers
  r = http.request options, authorizeUser
  r.end()
