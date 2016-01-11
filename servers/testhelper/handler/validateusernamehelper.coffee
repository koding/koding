querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRandomUsername
  generateDefaultRequestParams } = require '../index'


generateValidateUsernameRequestBody = (opts = {}) ->

  defaultBodyObject =
    username : generateRandomUsername()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateValidateUsernameRequestParams = (opts = {}) ->

  url  = generateUrl
    route : '-/validate/username'

  body = generateValidateUsernameRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateValidateUsernameRequestBody
  generateValidateUsernameRequestParams
}
