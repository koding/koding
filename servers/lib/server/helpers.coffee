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
  res.status(403).send "forbidden! (reason: #{err?.message or "no session!"})"

findUsernameFromKey = (req, res, callback) ->
  fetchJAccountByKiteUserNameAndKey req, (err, account)->
    if err
      console.error "we have a problem houston", err
      callback err, null
    else if not account
      console.error "couldnt find the account"
      res.status(401).end()
      callback false, null
    else
      callback false, account.profile.nickname

findUsernameFromSession = (req, res, callback) ->

  {clientId} = req.cookies
  unless clientId?
    return process.nextTick -> callback null

  koding.models.JSession.fetchSession clientId, (err, result) ->

    if err
      return callback err
    else unless result?
      return callback null

    {session} = result
    unless session?
    then callback null
    else callback null, session.username

fetchJAccountByKiteUserNameAndKey = (req, callback)->
  if req.fields
    {username, key} = req.fields
  else
    {username, key} = req.body

  {JKodingKey, JAccount} = koding.models
  {ObjectId} = require "bongo"

  JKodingKey.fetchByUserKey
    username: username
    key     : key
  , (err, kodingKey)=>
    console.error err, kodingKey.owner
    #if err or not kodingKey
    #  return callback(err, kodingKey)

    JAccount.one
      _id: ObjectId(kodingKey.owner)
    , (err, account)->
      if not account or err
         callback("couldnt find account #{kodingKey.owner}", null)
         return
      console.log "account ====================="
      console.log account
      console.log "======== account"
      req.account = account
      callback(err, account)

serve = (content, res)->
  res.header 'Content-type', 'text/html'
  res.send content

serveHome = (req, res, next) ->
  {JGroup} = bongoModels = koding.models
  {generateFakeClient}   = require "./client"

  generateFakeClient req, res, (err, client, session)->
    if err or not client
      console.error err
      return next()
    isLoggedIn req, res, (err, state, account)->
      if err
        res.status(500).send error_500()
        return console.error err

      client.connection.delegate = account

      {params}              = req
      {loggedIn, loggedOut} = JGroup.render
      fn                    = if state then loggedIn else loggedOut
      options = { client, account, bongoModels, params, session}

      fn.kodingHome options, (err, subPage)->
        return next()  if err
        serve subPage, res


isLoggedIn = (req, res, callback)->

  {JName} = koding.models

  findUsernameFromSession req, res, (err, username)->

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
  if oauthInfo.returnUrl
    query.returnUrl = oauthInfo.returnUrl
    delete oauthInfo.returnUrl
  query["foreignAuth.#{provider}"] = oauthInfo

  JSession.update {clientId}, $set:query, callback

redirectOauth = (res, options, err)->
  { returnUrl, provider } = options
  redirectUrl = "/Account/Oauth?provider=#{provider}&error=#{err}"
  redirectUrl = "#{redirectUrl}&returnUrl=#{returnUrl}"  if returnUrl
  res.redirect(redirectUrl)

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

handleClientIdNotFound = (res, req)->
  err = {message: "clientId is not set"}
  console.error JSON.stringify {req: req.body, err}
  return res.status(500).send err

getClientId = (req, res)->
  return req.cookies.clientId or req.pendingCookies.clientId

isInAppRoute = (name) ->
  [firstLetter] = name
  return false  if /^[0-9]/.test firstLetter # user nicknames can start with numbers
  return true   if firstLetter.toUpperCase() is firstLetter
  return false

module.exports = {
  error_
  error_404
  error_500
  authTemplate
  authenticationFailed
  findUsernameFromKey
  findUsernameFromSession
  fetchJAccountByKiteUserNameAndKey
  serve
  serveHome
  isLoggedIn
  getAlias
  addReferralCode
  saveOauthToSession
  redirectOauth
  handleClientIdNotFound
  getClientId
  isInAppRoute
}
