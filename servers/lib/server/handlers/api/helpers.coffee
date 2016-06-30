errors   = require './errors'
koding   = require '../../bongo'

KONFIG   = require 'koding-config-manager'
Jwt      = require 'jsonwebtoken'
async    = require 'async'
hat      = require 'hat'

apiErrors = require './errors'

SUGGESTED_USERNAME_MIN_LENGTH = 4
SUGGESTED_USERNAME_MAX_LENGTH = 15

sendApiError = (res, error) ->

  response  = { error }
  response ?= 'API Error'
  return res.status(error.status ? 403).send response


sendApiResponse = (res, data) ->

  response = { data }
  return res.status(200).send response


fetchAccount = (username, callback) ->

  koding.models.JAccount.one { 'profile.nickname': username }, (err, account) ->

    if err or not account
      return callback errors.internalError

    callback null, account


fetchGroup = (slug, callback) ->

  koding.models.JGroup.one { slug }, (err, group) ->

    if err
      return callback errors.internalError

    unless group
      return callback errors.groupNotFound

    callback null, group


fetchUserRolesFromSession = (session, callback) ->

  { groupName, username } = session

  fetchGroup groupName, (err, group) ->
    return callback err  if err

    fetchAccount username, (err, account) ->
      return callback err  if err

      group.fetchRolesByAccount account, (err, roles) ->
        return callback errors.internalError  if err

        callback null, roles ? []


checkApiAvailability = (options, callback) ->

  { JGroup }   = koding.models
  { apiToken } = options

  fetchGroup apiToken.group, (err, group) ->
    return callback err  if err

    unless group.isApiEnabled is true
      return callback errors.apiIsDisabled

    return callback null


isSuggestedUsernameLengthValid = (suggestedUsername) ->

  return SUGGESTED_USERNAME_MIN_LENGTH <= suggestedUsername?.length <= SUGGESTED_USERNAME_MAX_LENGTH


isUsernameLengthValid = (username) ->

  { JUser } = koding.models
  { minLength, maxLength } = JUser.getValidUsernameLengthRange()

  return minLength <= username?.length <= maxLength


validateJWTToken = (token, callback) ->

  { secret } = KONFIG.jwt

  Jwt.verify token, secret, { algorithms: ['HS256'] }, (err, decoded) ->

    { username, group } = decoded

    return callback errors.ssoTokenFailedToParse   if err
    return callback errors.invalidSSOTokenPayload  unless username
    return callback errors.invalidSSOTokenPayload  unless group
    return callback null, { username, group }


verifyApiToken = (token, callback) ->

  { JApiToken } = koding.models

  # checking if token is valid
  JApiToken.one { code: token }, (err, apiToken) ->

    return callback errors.internalError    if err
    return callback errors.invalidApiToken  unless apiToken

    checkApiAvailability { apiToken }, (err) ->
      return callback err  if err

      callback null, apiToken


verifySessionOrApiToken = (req, res, callback) ->

  { checkAuthorizationBearerHeader
    fetchSession } = require '../../helpers'

  token = checkAuthorizationBearerHeader req

  if token

    verifyApiToken token, (err, apiToken) ->
      return sendApiError res, err  if err

      # making sure subdomain is same with group slug
      unless apiToken.group in req.subdomains
        return sendApiError res, errors.invalidRequestDomain

      callback { apiToken }

  else

    fetchSession req, res, (err, session) ->

      if err or not session or not session.groupName?
        return sendApiError res, errors.unauthorizedRequest

      fetchUserRolesFromSession session, (err, roles) ->
        if err or 'admin' not in roles
          return sendApiError res, errors.unauthorizedRequest

        callback { session }


handleUsername = (username, suggestedUsername, callback) ->

  queue = []

  generateUsername = (next, results) ->
    _username = "#{suggestedUsername}#{hat(32)}"
    validateUsername _username, (err) ->
      return next err  if err
      next null, _username

  queue.push (next) ->
    # go next step and try suggestedUsername if no username is given
    return next null, null  unless username

    validateUsername username, (err) ->
      if err
        # try with suggestedUsername if one is given
        return next null, null  if suggestedUsername
        return next err

      # no err, pass username to next function
      next null, username

  queue.push (username_, next) ->
    # skip if username is returned from previous function
    return next null, username_  if username_

    # if suggestedUsername length is not valid, return error without trying
    unless isSuggestedUsernameLengthValid suggestedUsername
      return next apiErrors.outOfRangeSuggestedUsername

    # try 10 times to generate a valid username
    # will stop trying after first successful attempt
    async.retry 10, generateUsername, (err, generatedUsername) ->
      return next err  if err
      next null, generatedUsername

  async.waterfall queue, (err, username_) ->
    return callback err  if err
    return callback null, username_


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


module.exports = {
  sendApiError
  handleUsername
  verifyApiToken
  sendApiResponse
  validateJWTToken
  validateUsername
  checkApiAvailability
  isUsernameLengthValid
  verifySessionOrApiToken
  isSuggestedUsernameLengthValid

  SUGGESTED_USERNAME_MIN_LENGTH
  SUGGESTED_USERNAME_MAX_LENGTH
}
