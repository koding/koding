koding = require '../bongo'
KONFIG  = require 'koding-config-manager'


{
  isLoggedIn
} = require './session'


fetchGroupOAuthSettings = (provider, clientId, state, callback) ->

  { JSession, JGroup } = koding.models
  { hostname, protocol } = KONFIG

  JSession.one { clientId }, (err, session) ->
    return callback err  if err
    return callback { message: 'Session invalid' }  unless session

    unless session._id.equals state
      return callback { message: 'Invalid oauth flow' }

    { groupName: slug } = session

    JGroup.one { slug }, (err, group) ->
      return callback err  if err
      return callback { message: 'Group invalid' }  unless group

      if not group.config?[provider]?.enabled
        return callback { message: 'Integration not enabled yet.' }

      group.fetchDataAt provider, (err, data) ->
        return callback err  if err
        return callback { message: 'Integration settings invalid' }  unless data

        callback null, {
          url: group.config[provider].url
          applicationId: group.config[provider].applicationId
          applicationSecret: data.applicationSecret
          redirectUri: "#{protocol}//#{slug}.#{hostname}/-/oauth/#{provider}/callback"
        }


saveOauthToSession = (oauthInfo, clientId, provider, callback) ->
  { JSession } = koding.models

  query = { 'foreignAuthType': provider }

  if oauthInfo.returnUrl
    query.returnUrl = oauthInfo.returnUrl
    delete oauthInfo.returnUrl

  query["foreignAuth.#{provider}"] = oauthInfo

  JSession.update { clientId }, { $set:query }, callback


# Get user info with access token
fetchUserOAuthInfo = (provider, req, res, data) ->

  { scope, access_token } = data
  _provider = provider.toUpperCase()

  return (error, response, body) ->

    if error
      console.error "[#{_provider}][4/4] Failed to fetch user info:", error
      return failedReq provider, req, res

    if 'string' is typeof body
      try body = JSON.parse body

    unless body.id?
      console.error "[#{_provider}][4/4] Missing id in body:", body
      return failedReq provider, req, res

    { username, login, id, email, name } = body
    { returnUrl } = req.query
    { clientId }  = req.cookies

    username ?= login

    if name
      [firstName, restOfNames...] = name.split ' '
      lastName = restOfNames.join ' '

    resp = {
      email
      scope
      lastName
      username
      firstName
      returnUrl
      token     : access_token
      foreignId : String(id)
    }

    saveOauthToSession resp, clientId, provider, (err) ->
      redirectOauth err, req, res, { provider, returnUrl }

failedReq = (provider, req, res) ->
  redirectOauth 'could not grant access', req, res, { provider }

redirectOauth = (err, req, res, options) ->
  { returnUrl, provider } = options

  err = if err then "&error=#{err}" else ''
  redirectUrl = "/Home/Oauth?provider=#{provider}#{err}"

  # when returnUrl does not exist, handle oauth authentication in client side
  # this is temporary solution for authenticating registered users
  return res.redirect(redirectUrl)  unless returnUrl

  return res.status(400).send err  if err

  isLoggedIn req, res, (err, isUserLoggedIn, account) ->

    return res.status(400).send err  if err

    # here session belongs to koding domain (not subdomain)
    sessionToken = req.cookies.clientId

    username = account?.profile?.nickname
    client =
      context       :
        user        : username
      connection    :
        delegate    : account
      sessionToken  : sessionToken

    { JUser } = koding.models
    return JUser.authenticateWithOauth client, { provider, isUserLoggedIn }, (err, response) ->

      return res.status(400).send err  if err

      # user is logged in and session data exists
      res.redirect returnUrl

module.exports = {
  fetchGroupOAuthSettings
  saveOauthToSession
  fetchUserOAuthInfo
  redirectOauth
  failedReq
}
