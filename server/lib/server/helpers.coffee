koding = require './bongo'

error_messages =
  404: "Page not found"
  500: "Something wrong."

error_ = (code, message)->
  # Refactor this to use pistachio instead of underscore template engine - FKA
  staticpages     = require './staticpages'
  {template}      = require 'underscore'
  messageHTML     = message.split('\n')
    .map((line)-> "<p>#{line}</p>")
    .join '\n'

  {errorTemplate} = staticpages
  errorTemplate   = staticpages.notFoundTemplate if code is 404

  template errorTemplate, {code, error_messages, messageHTML}

error_404 = ->
  error_ 404, "Return to Koding home"

error_500 = ->
  error_ 500, "Something wrong with the Koding servers."

authTemplate = (msg)->
  {authRegisterTemplate} = require './staticpages'
  {template}             = require 'underscore'
  template authRegisterTemplate, {msg}

authenticationFailed = (res, err)->
  res.send "forbidden! (reason: #{err?.message or "no session!"})", 403

findUsernameFromSession = (req, res, callback) ->
  {clientId} = req.cookies
  unless clientId?
    process.nextTick -> callback null, no, ""
  else
    koding.models.JSession.fetchSession clientId, (err, result)->
      if err
        console.error err
        callback err, undefined, ""
      else unless result?
        res.send 403, 'Access denied!'
        callback null, false, ""

      { session } = result

      unless session?
        res.send 403, 'Access denied!'
        callback null, false, ""
      else
        callback null, false, session.username

serve = (content, res)->
  res.header 'Content-type', 'text/html'
  res.send content


serveHome = (req, res, next)->
  {JGroup} = bongoModels = koding.models
  isCustomPreview = req.cookies["custom-partials-preview-mode"]
  {generateFakeClient}   = require "./client"

  generateFakeClient req, res, (err, client)->
    if err or not client
      console.error err
      return next()
    isLoggedIn req, res, (err, state, account)->
      if err
        res.send 500, error_500()
        return console.error err

      {loggedIn, loggedOut} = JGroup.render
      {params}              = req
      fn                    = if state then loggedIn else loggedOut
      fn.kodingHome {client, account, bongoModels, params, isCustomPreview}, (err, subPage)->
        return next()  if err
        serve subPage, res


isLoggedIn = (req, res, callback)->
  {JName} = koding.models
  findUsernameFromSession req, res, (err, isLoggedIn, username)->
    return callback null, no, {}  unless username
    JName.fetchModels username, (err, result)->
      return callback null, no, {}  unless result?

      { models } = result

      return callback null, no, {}  if err or not models?.first
      user = models.last
      user.fetchAccount "koding", (err, account)->
        if err or not account or account.type is 'unregistered'
          return callback err, no, account
        return callback null, yes, account

saveOauthToSession = (oauthInfo, clientId, provider, callback)->
  {JSession}                       = koding.models
  query                            = {"foreignAuthType" : provider}
  query["foreignAuth.#{provider}"] = oauthInfo

  JSession.update {clientId}, $set:query, callback

renderOauthPopup = (res, locals)->
  templateFn       = require "./templates/oauth_popup.coffee"
  renderedTemplate = templateFn locals

  serve renderedTemplate, res

getAlias = do->
  caseSensitiveAliases = ['auth']
  (url)->
    rooted = '/' is url.charAt 0
    url = url.slice 1  if rooted
    if url in caseSensitiveAliases
      alias = "#{url.charAt(0).toUpperCase()}#{url.slice 1}"
    if alias and rooted then "/#{alias}" else alias

# adds referral code into cookie if exists
addReferralCode = (req, res)->
  match = req.path.match(/\/R\/(.*)/)
  if match and refCode = match[1]
    res.cookie "referrer", refCode, { maxAge: 900000, secure: true }

module.exports = {
  error_
  error_404
  error_500
  authTemplate
  authenticationFailed
  findUsernameFromSession
  serve
  serveHome
  isLoggedIn
  getAlias
  addReferralCode
  saveOauthToSession
  renderOauthPopup
}
