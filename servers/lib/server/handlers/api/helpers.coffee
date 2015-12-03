errors = require './errors'
koding = require '../../bongo'

sendApiError = (res, error) ->

  response = { error }
  return res.status(error.status).send response


sendApiResponse = (res, data) ->

  response = { data }
  return res.status(200).send response


checkApiAvailability = (options, callback) ->

  { JGroup }  = koding.models
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

  if 4 <= suggestedUsername?.length <= 15
  then yes
  else no


isUsernameLengthValid = (username) ->

  { JUser } = koding.models
  { minLength, maxLength } = JUser.getValidUsernameLengthRange()

  if minLength <= username?.length <= maxLength
  then yes
  else no



module.exports = {
  sendApiError
  sendApiResponse
  isUsernameLengthValid
  checkApiAvailability
  isSuggestedUsernameLengthValid
}

