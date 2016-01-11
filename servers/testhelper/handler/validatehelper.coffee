querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateDefaultRequestParams } = require '../index'


generateValidateRequestBody = (opts = {}) ->

  defaultBodyObject =
    fields     :
      username : ''
      email    : ''

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateValidateRequestParams = (opts = {}) ->

  url  = generateUrl
    route : '-/validate'

  body = generateValidateRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateValidateRequestBody
  generateValidateRequestParams
}
