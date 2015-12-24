errors = require './errors'
koding = require '../../bongo'

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


module.exports = {
  sendApiError
  sendApiResponse
  checkApiAvailability
  isUsernameLengthValid
  isSuggestedUsernameLengthValid

  SUGGESTED_USERNAME_MIN_LENGTH
  SUGGESTED_USERNAME_MAX_LENGTH
}

