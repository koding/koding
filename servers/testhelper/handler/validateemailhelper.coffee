querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateDefaultRequestParams } = require '../index'


generateValidateEmailRequestBody = (opts = {}) ->

  defaultBodyObject =
    email     : generateRandomEmail()
    tfcode    : ''
    password  : ''

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateValidateEmailRequestParams = (opts = {}) ->

  url  = generateUrl
    route : '-/validate/email'

  body = generateValidateEmailRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateValidateEmailRequestBody
  generateValidateEmailRequestParams
}
