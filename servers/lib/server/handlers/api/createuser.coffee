hat                                = require 'hat'
koding                             = require '../../bongo'
{ daisy }                          = require 'bongo'
{ getClientId
  handleClientIdNotFound
  checkAuthorizationBearerHeader } = require '../../helpers'

module.exports = createUser = (req, res, next) ->

  { JUser } = koding.models

  clientId = getClientId req, res
  return handleClientIdNotFound res, req  unless clientId

  # validating req params
  { error, token, username, email, firstName, lastName } = validateRequest req
  return res.status(error.statusCode).send(error.message)  if error

  client   = null
  apiToken = null

  queue = [

    ->
      validateData { token, username }, (err, data) ->
        return res.status(err.statusCode).send(err.message)  if err
        { username, apiToken } = data
        queue.next()

    ->
      # creating a client which will be used in JUser.convert
      context = { group : apiToken.group }
      koding.fetchClient clientId, context, (client_) ->
        client = client_

        # when there is an error in the fetchClient, it returns message in it
        if client.message
          console.error JSON.stringify { req, client }
          return res.status(500).send client.message

        clientIPAddress = req.headers['x-forwarded-for'] or req.connection?.remoteAddress
        client.clientIP = (clientIPAddress.split ',')[0]  if clientIPAddress

        queue.next()

    ->
      # registering a new user to the apiToken group
      password = passwordConfirm = hat()

      userData = {
        email, username, firstName, lastName, password, passwordConfirm
        agree     : 'on'
        groupName : apiToken.group
      }

      JUser.convert client, userData, (err, data) ->

        if err
          response = if err.errors?
          then "#{err.message}: #{Object.keys err.errors}"
          else err.message

          return res.status(400).send response

        { user } = data
        return res.status(500).send 'failed to create user account'  unless user
        return res.status(200).send { username : user.username }     if user

  ]

  daisy queue


validateData = (data, callback) ->

  { JUser, JApiToken } = koding.models
  { token, username }  = data

  apiToken = null

  queue = [

    ->
      # checking if token is valid
      JApiToken.one { code : token }, (err, apiToken_) ->
        if err
          return callback { statusCode : 500, message : 'an error occurred' }
        unless apiToken_
          return callback { statusCode : 400, message : 'invalid token!' }
        apiToken = apiToken_
        queue.next()

    ->
      # creating a random username with first letters of group slug in front
      username or= "#{apiToken.group.substring(0, 4)}#{hat(32)}"
      # checking if username is available
      JUser.usernameAvailable username, (err, { kodingUser, forbidden }) ->
        if err
          return callback { statusCode : 500, message : 'an error occurred' }
        if kodingUser or forbidden
          return callback { statusCode : 400, message : 'username is not available' }
        queue.next()

    -> callback null, { apiToken, username }

  ]

  daisy queue



validateRequest = (req) ->

  token = null
  { username, email, firstName, lastName } = req.body

  errors =
    invalidRequest      :
      statusCode        : 400
      message           : 'invalid request'
    unauthorizedRequest :
      statusCode        : 401
      message           : 'unauthorized request'

  unless email
    return { error : errors.invalidRequest }

  unless token = checkAuthorizationBearerHeader req
    return { error : errors.unauthorizedRequest }

  return { error : null, token, username, email, firstName, lastName }

