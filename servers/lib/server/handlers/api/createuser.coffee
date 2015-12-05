hat                                = require 'hat'
koding                             = require '../../bongo'
apiErrors                          = require './errors'
{ daisy }                          = require 'bongo'
{ getClientId
  handleClientIdNotFound
  checkAuthorizationBearerHeader } = require '../../helpers'
{ sendApiError
  sendApiResponse
  checkApiAvailability
  isUsernameLengthValid
  isSuggestedUsernameLengthValid } = require './helpers'


module.exports = createUser = (req, res, next) ->

  { JUser } = koding.models

  clientId = getClientId req, res
  return handleClientIdNotFound res, req  unless clientId

  # validating req params
  { error, token, username, email
    firstName, lastName, suggestedUsername } = validateRequest req

  return sendApiError res, error  if error

  client   = null
  apiToken = null

  queue = [

    ->
      validateData { token, username, suggestedUsername }, (err, data) ->
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

      # here we don't check if email is in allowed domains
      # because the user who has the api token must be a group admin
      # they should be able to use any email they want for their own team  ~ OK
      options  = { ignoreAllowedDomainCheck : yes }

      JUser.convert client, userData, options, (err, data) ->

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
  { token, username, suggestedUsername } = data

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
      checkApiAvailability { apiToken }, (err) ->
        return callback err  if err
        queue.next()

    ->
      handleUsername username, suggestedUsername, (err, username_) ->
        return callback err  if err
        username = username_
        queue.next()

    -> callback null, { apiToken, username }

  ]

  daisy queue


handleUsername = (username, suggestedUsername, callback) ->

  queue = []

  if username
    queue.push ->
      validateUsername username, (err) ->
        # return username if it is valid
        return callback null, username  unless err
        # return if there is no suggestedUsername
        return callback err  unless suggestedUsername
        queue.next()

  if suggestedUsername
    queue.push ->
      # if suggestedUsername length is not valid, return error without trying
      unless isSuggestedUsernameLengthValid suggestedUsername
        return callback apiErrors.outOfRangeSuggestedUsername
      queue.next()

    # try usernames with different suffixes 10 times
    for i in [0..10]
      queue.push ->
        _username = "#{suggestedUsername}#{hat(32)}"
        validateUsername _username, (err) ->
          return callback null, _username  unless err
          queue.next()

    # if username is still invalid, let it go
    queue.push -> callback apiErrors.usernameAlreadyExists

  daisy queue


validateUsername = (username, callback) ->

  { JUser } = koding.models

  # checking if username has valid length
  unless isUsernameLengthValid username
    return callback apiErrors.outOfRangeUsername

  # checking if username is available
  JUser.usernameAvailable username, (err, { kodingUser, forbidden }) ->
    return callback apiErrors.internalError          if err
    return callback apiErrors.usernameAlreadyExists  if kodingUser or forbidden
    return callback null



validateRequest = (req) ->

  token = null
  { username, suggestedUsername, email, firstName, lastName } = req.body

  unless email
    return { error : apiErrors.invalidInput }

  unless username or suggestedUsername
    return { error : apiErrors.invalidInput }

  unless token = checkAuthorizationBearerHeader req
    return { error : apiErrors.unauthorizedRequest }

  return { error : null, token, username, email, firstName, lastName, suggestedUsername }

