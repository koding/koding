
{ daisy } = require 'bongo'

module.exports = (req, res, next) ->

  { JAccount, JGroup, JUser, JApiToken } = (require '../bongo').models

  # validating req params
  { error, token, username } = validateRequest req
  return res.status(error.statusCode).send(error.message)  if error

  account  = null
  apiToken = null

  queue = [

    ->
      # checking if token is valid
      JApiToken.one { code : token }, (err, apiToken_) ->
        return res.status(500).send 'an error occurred'  if err
        return res.status(400).send 'invalid token!'     unless apiToken_
        apiToken = apiToken_
        queue.next()

    ->
      # checking if user exists
      JAccount.one { 'profile.nickname' : username }, (err, account_) ->
        return res.status(500).send 'an error occurred'  if err
        return res.status(400).send 'invalid username!'  unless account_
        account = account_
        queue.next()

    ->
      # checking if user is a member of the group of api token
      client = { connection : { delegate : account } }
      account.checkGroupMembership client, apiToken.group, (err, isMember) ->
        return res.status(500).send 'an error occurred'  if err
        return res.status(400).send 'invalid request'    unless isMember
        queue.next()

    ->
      # creating and sending an SSO token
      data    = { username, group : apiToken.group }
      options = { expiresInMinutes : 60 }
      token   = JUser.createJWT data, options

      return res.status(200).send { token }

  ]

  daisy queue



validateRequest = (req) ->

  { username } = req.body

  errors =
    invalidRequest      :
      statusCode        : 400
      message           : 'invalid request'
    unauthorizedRequest :
      statusCode        : 401
      message           : 'unauthorized request'

  unless username
    return { error : errors.invalidRequest }

  unless req.headers?.authorization
    return { error : errors.unauthorizedRequest }
  parts = req.headers.authorization.split ' '

  unless parts.length is 2 and parts[0] is 'Bearer'
    return { error : errors.unauthorizedRequest }
  token = parts[1]

  unless typeof token is 'string'
    return { error : errors.unauthorizedRequest }

  return { error : null, token, username }

