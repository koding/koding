KONFIG    = require 'koding-config-manager'
apiErrors = require './apierrors'
{ clone } = require 'underscore'
isUUID    = require 'uuid-validate'

purify = (data) ->

  if data?.get? then data.get() else data


getConstructorName = (name, api) ->

  for own model, konstructor of api
    return model  if model.toLowerCase() is name.toLowerCase()


getContextFromSession = (session) ->

  { clientId: sessionToken, groupName: group } = session
  return { userArea: { group }, sessionToken }


sendApiError = (res, error) ->

  return res.status(error.status ? 403).send error


sendResponse = (res) -> (err, data) ->

  if err
    sendApiError res, { ok: false, error: err }

  else
    res.status(200)
      .send { ok: true, data }
      .end()


processHookRequests = (req, res) ->

  # TODO update this to use a dynamically generated list of hook req. ~ GG
  # this is currently GitHub only, we can remove this step from here
  # and move it to the Hooks implementation at some point if we need.
  if /^GitHub-/.test req.get 'user-agent'
    if req.get('X-GitHub-Event') is 'ping'
      (sendResponse res) null, { pong: true }
      return yes

  return no


processPayload = (payload, callback) ->

  [ error, data ] = payload[0].arguments

  error ?= null
  data  ?= null

  if Array.isArray data
    data = data.map (_data) -> purify _data
  else
    data = purify data

  payload = { ok: true, error, data }

  callback payload


getToken = (req) ->

  return null  unless req.headers?.authorization
  parts = req.headers.authorization.split ' '

  return null  unless parts.length is 2 and parts[0] is 'Bearer'
  token = parts[1]

  return null  unless typeof token is 'string' and token.length > 0

  return token


parseRequest = (req, res) ->

  { token, model, id } = req.params

  if token and not id and not isUUID token
    [ model, id ] = [ token, model ]
    token = undefined

  unless model
    sendApiError res, apiErrors.invalidInput
    return

  [ model, method ] = model.split '.'

  unless method
    sendApiError res, apiErrors.invalidInput
    return

  token ?= getToken req

  return { model, id, method, token }


updateSessionTimestamp = (session, callback) ->

  session.lastAccess = lastAccess = new Date
  session.update { $set: { lastAccess } }, (err) ->
    return callback apiErrors.unauthorizedRequest  if err
    callback null, session


fetchSession = (api, options, callback) ->

  { token } = options

  unless token

    api.JSession.createSession options, (err, res) ->
      if err or not res?.session
        return callback apiErrors.unauthorizedRequest

      callback null, res.session

    return

  api.JSession.one { clientId: token }, (err, session) ->

    if err
      return callback apiErrors.unauthorizedRequest

    if session

      if session.isGuestSession()
        session.remove()
        return callback apiErrors.unauthorizedRequest

      if session.getAt 'sessionData.apiSession'
        api.JApiToken.fetchGroup (session.getAt 'groupName'), (err) ->
          return callback err  if err
          updateSessionTimestamp session, callback

      else
        updateSessionTimestamp session, callback

      return

    api.JApiToken.createSessionByToken token, (err, session) ->

      if err or not session
        return callback apiErrors.unauthorizedRequest

      updateSessionTimestamp session, callback


sendSignatureErr = (signatures, method, res) ->

  # Make signatures human readable ~ GG
  signatures = signatures.map (signature) ->
    [
      signature
        .replace /,F$/, ''
        .replace /O/g, 'Object'
        .replace /S/g, 'String'
        .replace /F/g, 'Function'
        .replace /N/g, 'Number'
        .replace /B/g, 'Boolean'
        .replace /A/g, 'Array'
    ]

  signatures = signatures[0]  if signatures.length is 1
  signaturesMessage = if signatures.length is 1 and signatures[0] is 'Function'
  then 'No parameter required'
  else "Possible signatures are #{JSON.stringify(signatures).replace /"/g, ''}"

  sendApiError res, {
    ok: false
    error: "
      Unrecognized signature for '#{method}' #{signaturesMessage}
    "
    signatures
  }


module.exports = RemoteHandler = (koding) ->

  api = koding.models

  return (req, res) ->

    return  unless parsedRequest = parseRequest req, res
    { model, id, method, token } = parsedRequest

    options = {}
    options.token = token   if token
    options.group = req.body.groupName
    customContext = req.body.username

    if "#{model}.#{method}" is 'JUser.login'
      if not options.group or not customContext
        sendApiError res, apiErrors.invalidInput
        return

    else if not token
      sendApiError res, apiErrors.unauthorizedRequest
      return

    fetchSession api, options, (err, session) ->

      if err
        sendApiError res, err
        return

      return  if processHookRequests req, res

      context         = getContextFromSession session
      constructorName = getConstructorName model, api

      if customContext
        context.customContext = "custom:#{customContext}"

      unless constructorName
        sendApiError res, apiErrors.invalidInput
        return

      body = if req.body then clone req.body else null
      req.body ?= {}
      req.body  = context

      args = if Array.isArray body
      then body
      else if (Object.keys body).length
      then [body]
      else []

      args.push (->)

      callbacks = { 1: [args.length - 1] }

      type = if id then 'instance' else 'static'

      unless api[constructorName].getSignature type, method
        sendApiError res, { ok: false, error: 'No such method' }
        return

      [validCall, signatures] = api[constructorName].testSignature type, method, args

      unless validCall
        sendSignatureErr signatures, "#{constructorName}.#{method}", res
        return

      bongoRequest = {
        arguments: args
        callbacks
        method: {
          constructorName
          method
          type
        }
      }

      bongoRequest.method.id = id  if id
      req.body.queue = [ bongoRequest ]

      (koding.expressify {
        rateLimitOptions: KONFIG.nodejsRateLimiterForApi
        processPayload
      }) req, res
