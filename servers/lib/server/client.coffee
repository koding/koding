{ argv }         = require 'optimist'
KONFIG           = require 'koding-config-manager'
bongo            = require './bongo'
uuid             = require 'uuid'

{ setSessionCookie } = require './helpers'

handleError = (err, callback) ->
  console.error err
  return callback? err


updateCookie = (req, res, session) ->

  { clientId }       = session
  { maxAge, secure } = KONFIG.sessionCookie

  # if we already have the same cookie in request, dont do anything
  unless req?.cookies?.clientId is clientId

    # set cookie as pending cookie
    req.pendingCookies or= {}
    req.pendingCookies.clientId = clientId

    setSessionCookie res, clientId

  unless req?.cookies?._csrf

    csrfToken = uuid.v4()
      # set cookie as pending cookie
    req.pendingCookies or= {}
    req.pendingCookies._csrf = csrfToken

    expires = new Date Date.now() + maxAge
    res.cookie '_csrf', csrfToken, { expires, secure }


generateFakeClientFromReq = (req, res, callback) ->

  { clientId } = req.cookies

  # TODO change this with Team product
  groupName = 'koding'

  # if client id is not set, check for pendingCookies
  if not clientId and req.pendingCookies?.clientId
    clientId = req.pendingCookies.clientId

  generateFakeClient { clientId, groupName }, (err, fakeClient, session) ->

    return callback err  if err

    { delegate } = fakeClient.connection

    updateCookie req, res, session

    return callback null, fakeClient, session


generateFakeClient = (options, callback) ->

  { clientId, groupName } = options

  fakeClient      =
    context       :
      group       : 'koding'
      user        : 'guest-1'
    connection    :
      delegate    : null
      groupName   : 'koding'
    impersonating : false

  return callback null, fakeClient  unless clientId

  { JSession, JAccount } = bongo.models

  JSession.fetchSession { clientId }, (err, response) ->

    return handleError err, callback  if err

    if not response or not response.session
      return handleError new Error 'Session is not set', callback

    { session }             = response
    { username, groupName } = session

    JAccount.one { 'profile.nickname': username }, (err, account) ->
      # we can ignore err here
      prepareFakeClient fakeClient, { groupName, session, username, account }
      return callback null, fakeClient, session

prepareFakeClient = (fakeClient, options) ->
  { groupName, session, username, account, sessionToken } = options

  { JAccount }      = bongo.models

  unless account
    account         = new JAccount
    account.profile = { nickname: username }
    account.type    = 'unregistered'

  fakeClient.sessionToken = sessionToken ? session.clientId

  # set username into context
  fakeClient.context     or= {}
  fakeClient.context.group = groupName or fakeClient.context.group
  fakeClient.context.user  = session.username or fakeClient.context.user

  # create connection property
  fakeClient.connection         or= {}
  fakeClient.connection.delegate  = account or fakeClient.connection.delegate
  fakeClient.connection.groupName = groupName or fakeClient.connection.groupName

  fakeClient.impersonating = session.impersonating or false


module.exports = { generateFakeClient: generateFakeClientFromReq, updateCookie }
