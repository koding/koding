{
  renderOauthPopup
}          = require './helpers'

{facebook} = KONFIG
http       = require "https"
koding     = require './bongo'
{JSession} = koding.models
{decode}   = require "querystring"

module.exports = (req, res) ->
  access_token = null

  # TODO: move to config
  facebook =
    clientId     : "475071279247628"
    clientSecret : "65cc36108bb1ac71920dbd4d561aca27"
    redirect_url : "http://localhost:3020/-/oauth/facebook/callback"

  {clientId} = req.cookies
  {code}     = req.query
  unless code
    renderOauthPopup res, {error:{message:"No code"}, provider:"facebook"}
    return

  url = "https://graph.facebook.com/oauth/access_token?client_id=#{facebook.clientId}&redirect_uri=#{facebook.redirect_url}&client_secret=#{facebook.clientSecret}&code=#{code}"

  http.get url, (httpResp)->
    rawResp = ""
    httpResp.on "data", (chunk) -> rawResp += chunk
    httpResp.on "end", ->
      access_token = decode(rawResp).access_token
      console.log ">>> access_token", access_token

      if access_token
        options =
          host    : "graph.facebook.com"
          path    : "/me?access_token=#{access_token}"
          method  : "GET"
        r = http.request options, fetchUserInfo
        r.end()

  fetchUserInfo = (userInfoResp) ->
    rawResp = ""
    userInfoResp.on "data", (chunk) -> rawResp += chunk
    userInfoResp.on "end", ->
      {id, username} = JSON.parse rawResp

      console.log rawResp

      JSession.one {clientId}, (err, session)->
        if err then console.log err
        else
          facebookResp = {access_token, username}
          facebookResp["foreignId"] = id

          session.update $set: {"foreignAuth.facebook": facebookResp}, (err)->
            if err then console.log err
            else
              renderOauthPopup res, {error:null, provider:"facebook"}
