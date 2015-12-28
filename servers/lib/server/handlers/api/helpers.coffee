errors   = require './errors'
koding   = require '../../bongo'

{ argv } = require 'optimist'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")

Jwt      = require 'jsonwebtoken'

SUGGESTED_USERNAME_MIN_LENGTH = 4
SUGGESTED_USERNAME_MAX_LENGTH = 15

sendApiError = (res, error) ->

  response = { error }
  return res.status(error.status).send response


sendApiResponse = (res, data) ->

  response = { data }
  return res.status(200).send response


checkApiAvailability = (options, callback) ->

  { JGroup }   = koding.models
  { apiToken } = options

  JGroup.one { slug : apiToken.group }, (err, group) ->

    if err
      return callback errors.internalError

    unless group
      return callback errors.groupNotFound

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
module.exports = {
  sendApiError
  validateJWTToken
  sendApiResponse
  checkApiAvailability
  isUsernameLengthValid
  isSuggestedUsernameLengthValid

  SUGGESTED_USERNAME_MIN_LENGTH
  SUGGESTED_USERNAME_MAX_LENGTH
}

