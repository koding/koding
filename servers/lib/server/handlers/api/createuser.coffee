hat                                = require 'hat'
async                              = require 'async'
koding                             = require '../../bongo'
apiErrors                          = require './errors'
{ getClientId
  handleClientIdNotFound
  checkAuthorizationBearerHeader } = require '../../helpers'
{ sendApiError
  handleUsername
  verifyApiToken
  sendApiResponse
  validateUsername
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

  user     = null
  client   = null
  apiToken = null

  queue = [

    (next) ->
      validateData { token, username, suggestedUsername }, (err, data) ->
        return next err  if err
        { username, apiToken } = data
        next()

    (next) ->
      # creating a client which will be used in JUser.convert
      context = { group : apiToken.group }
      koding.fetchClient clientId, context, (client_) ->
        client = client_

        # when there is an error in the fetchClient, it returns message in it
        return next apiErrors.internalError  if client.message

        clientIPAddress = req.headers['x-forwarded-for'] or req.connection?.remoteAddress
        client.clientIP = (clientIPAddress.split ',')[0]  if clientIPAddress
        next()

    (next) ->
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
      options  = { skipAllowedDomainCheck : yes }

      JUser.convert client, userData, options, (err, data) ->

        if err?.message is 'Email is already in use!'
          return next apiErrors.emailAlreadyExists

        if err?.message is 'Your email domain is not in allowed domains for this group'
          return next apiErrors.invalidEmailDomain

        return next apiErrors.internalError  if err

        { user } = data
        return next apiErrors.failedToCreateUser  unless user
        next()

  ]

  async.series queue, (err) ->
    return sendApiError    res, err  if err
    return sendApiResponse res, { username : user.username }


validateData = (data, callback) ->

  { token, username, suggestedUsername } = data

  verifyApiToken token, (err, apiToken) ->
    return callback err  if err

    handleUsername username, suggestedUsername, (err, username) ->
      return callback err  if err

      callback null, { apiToken, username }


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
