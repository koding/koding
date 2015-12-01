hat                                = require 'hat'
koding                             = require '../../bongo'
apiErrors                          = require './errors'
{ daisy }                          = require 'bongo'
{ getClientId
  handleClientIdNotFound
  checkAuthorizationBearerHeader } = require '../../helpers'
{ sendApiError
  sendApiResponse
  checkApiTokenAvailability }       = require './helpers'


module.exports = createUser = (req, res, next) ->

  { JUser } = koding.models

  clientId = getClientId req, res
  return handleClientIdNotFound res, req  unless clientId

  # validating req params
  { error, token, username, email, firstName, lastName } = validateRequest req
  return sendApiError res, error  if error

  client   = null
  apiToken = null

  queue = [

    ->
      validateData { token, username }, (err, data) ->
        return sendApiError res, err  if err
        { username, apiToken } = data
        queue.next()

    ->
      # creating a client which will be used in JUser.convert
      context = { group : apiToken.group }
      koding.fetchClient clientId, context, (client_) ->
        client = client_

        # when there is an error in the fetchClient, it returns message in it
        if client.message
          return sendApiError res, apiErrors.internalError

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

        if err?.message is 'Email is already in use!'
          return sendApiError res, apiErrors.emailAlreadyExists

        if err?.message is 'Your email domain is not in allowed domains for this group'
          return sendApiError res, apiErrors.invalidEmailDomain

        return sendApiError res, apiErrors.internalError  if err

        { user } = data
        return sendApiError    res, apiErrors.failedToCreateUser   unless user
        return sendApiResponse res, { username : user.username }

  ]

  daisy queue


validateData = (data, callback) ->

  { JUser, JGroup, JApiToken } = koding.models
  { token, username }          = data

  apiToken = null

  queue = [

    ->
      # checking if token is valid
      JApiToken.one { code : token }, (err, apiToken_) ->
        return callback apiErrors.internalError    if err
        return callback apiErrors.invalidApiToken  unless apiToken_

        apiToken = apiToken_
        queue.next()

    ->
      # creating a random username with first letters of group slug in front
      username or= "#{apiToken.group.substring(0, 4)}#{hat(32)}"
      # checking if username is available
      JUser.usernameAvailable username, (err, { kodingUser, forbidden }) ->
        return callback apiErrors.internalError          if err
        return callback apiErrors.usernameAlreadyExists  if kodingUser or forbidden
        queue.next()

    ->
      checkApiTokenAvailability { apiToken }, (err) ->
        return callback err  if err
        queue.next()

    -> callback null, { apiToken, username }

  ]

  daisy queue


validateRequest = (req) ->

  token = null
  { username, email, firstName, lastName } = req.body

  unless email
    return { error : apiErrors.invalidInput }

  unless token = checkAuthorizationBearerHeader req
    return { error : apiErrors.unauthorizedRequest }

  return { error : null, token, username, email, firstName, lastName }

