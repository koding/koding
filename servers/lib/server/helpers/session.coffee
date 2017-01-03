koding = require '../bongo'
KONFIG  = require 'koding-config-manager'

errSessionNotFound = new Error 'session not found'

fetchSession = (req, res, callback) ->
  { clientId } = req.cookies
  return callback errSessionNotFound unless clientId?
  koding.models.JSession.fetchSession { clientId }, (err, result) ->
    return callback err if err
    return callback errSessionNotFound  unless result?.session?
    return callback null, result.session


findUsernameFromSession = (req, res, callback) ->
  fetchSession req, res, (err, session) ->
    callback err, session?.username


isLoggedIn = (req, res, callback) ->
  findUsernameFromSession req, res, (err, username) ->
    return callback err  unless username

    koding.models.JAccount.one { 'profile.nickname' : username }, (err, account) ->
      if err or not account or account.type isnt 'registered'
        return callback err, no, account
      return callback null, yes, account


# adds referral code into cookie if exists
addReferralCode = (req, res) ->
  match = req.path.match(/\/R\/(.*)/)
  if match and refCode = match[1]
    res.cookie 'referrer', refCode, { maxAge: 900000, secure: true }


handleClientIdNotFound = (res, req) ->
  err = { message: 'clientId is not set' }
  console.error JSON.stringify { req: req.body, err }
  return res.status(500).send err

getClientId = (req, res) ->
  return req.cookies.clientId or req.pendingCookies.clientId

{ sessionCookie } = KONFIG

setSessionCookie = (res, sessionId, options = {}) ->
  options.path    = '/'
  options.secure  = sessionCookie.secure
  options.expires = new Date(Date.now() + sessionCookie.maxAge)

  # somehow we are sending two clientId cookies in some cases, last writer wins.
  res.clearCookie 'clientId', options
  res.cookie 'clientId', sessionId, options


checkAuthorizationBearerHeader = (req) ->
  return null  unless req.headers?.authorization
  parts = req.headers.authorization.split ' '

  return null  unless parts.length is 2 and parts[0] is 'Bearer'
  token = parts[1]

  return null  unless typeof token is 'string' and token.length > 0
  return token


module.exports = {
  fetchSession
  findUsernameFromSession
  isLoggedIn
  addReferralCode
  handleClientIdNotFound
  getClientId
  setSessionCookie
  checkAuthorizationBearerHeader
}
