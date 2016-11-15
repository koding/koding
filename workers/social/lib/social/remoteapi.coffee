KONFIG    = require 'koding-config-manager'
apiErrors = require './apierrors'
{ clone } = require 'underscore'

purify = (data) ->

  if data?.get? then data.get() else data


getConstructorName = (name, Models) ->

  for own model, konstructor of Models
    return model  if model.toLowerCase() is name


sendApiError = (res, error) ->

  return res.status(error.status ? 403).send error


sendResponse = (res) -> (err, data) ->

  if err
    sendApiError res, { ok: false, error: err }

  else
    res.status(200)
      .send { ok: true, data }
      .end()

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

  { model, id } = req.params

  unless model
    sendApiError res, apiErrors.invalidInput
    return

  [ model, method ] = model.split '.'

  unless method
    sendApiError res, apiErrors.invalidInput
    return

  unless sessionToken = getToken req
    sendApiError res, apiErrors.unauthorizedRequest
    return

  return { model, id, method, sessionToken }


module.exports = RemoteHandler = (koding) ->

  Models = koding.models

  return (req, res) ->

    return  unless parsedRequest = parseRequest req, res

    { model, id, method, sessionToken } = parsedRequest

    constructorName = getConstructorName model, Models

    unless constructorName
      sendApiError res, apiErrors.invalidInput
      return

    body = if req.body then clone req.body else null
    req.body ?= {}
    req.body  = { userArea: {}, sessionToken }

    args = if Array.isArray body
    then body
    else if (Object.keys body).length
    then [body]
    else []

    args.push (->)

    callbacks = { 1: [args.length - 1] }

    type = if id then 'instance' else 'static'

    if type is 'static'
      unless Models[constructorName]?[method]
        sendApiError res, { ok: false, error: 'No such method' }
        return

    validCall = Models[constructorName].testSignature type, method, args

    unless validCall

      sendApiError res, {
        ok: false
        error: "unrecognized signature: #{constructorName}.#{method}"
      }

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
      rateLimitOptions: KONFIG.nodejsRateLimiter
      processPayload
    }) req, res
