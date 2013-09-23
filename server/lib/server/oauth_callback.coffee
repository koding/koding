{github}= KONFIG

{ serve
  saveOauthToSession
}       = require './helpers'

http    = require "https"
jade    = require "jade"
express = require 'express'
app     = express()

module.exports = (req, res) ->
  renderLoginTemplate = (resp, res)->
    saveOauthToSession resp, ->
      {projectRoot}    = KONFIG
      oauthLoginPath   = "#{projectRoot}/website/jade/oauth_login.jade"

      template         = require('fs').readFileSync(oauthLoginPath, 'utf8')
      jadeFn           = jade.compile(template)
      renderedTemplate = jadeFn({error:null, provider:"github"})

      serve renderedTemplate, res

  {provider}    = req.params
  code          = req.query.code
  access_token  = null

  console.log ">>> code", code

  unless code
    {loginFailureTemplate} = require './staticpages'
    serve loginFailureTemplate, res
    return

  headers =
    "Accept"     : "application/json"
    "User-Agent" : "Koding"

  authorizeUser = (authUserResp)->
    rawResp = ""
    authUserResp.on "data", (chunk) -> rawResp += chunk
    authUserResp.on "end", ->
      {access_token} = JSON.parse rawResp
      console.log ">>> access_token", access_token
      if access_token
        options =
          host    : "api.github.com"
          path    : "/user?access_token=#{access_token}"
          method  : "GET"
          headers : headers
        r = http.request options, fetchUserInfo
        r.end()

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

      if not email? or email is ""
        options =
          host    : "api.github.com"
          path    : "/user/emails?access_token=#{access_token}"
          method  : "GET"
          headers : headers
        r = http.request options, (newResp)-> fetchUserEmail newResp, resp
        r.end()
      else
        renderLoginTemplate resp, res

  fetchUserEmail = (userEmailResp, originalResp)->
    rawResp = ""
    userEmailResp.on "data", (chunk) -> rawResp += chunk
    userEmailResp.on "end", ->
      email = JSON.parse(rawResp)[0]
      originalResp.email = email
      renderLoginTemplate originalResp, res

  options =
    host   : "github.com"
    path   : "/login/oauth/access_token?client_id=#{github.clientId}&client_secret=#{github.clientSecret}&code=#{code}"
    method : "POST"
    headers : headers
  r = http.request options, authorizeUser
  r.end()
