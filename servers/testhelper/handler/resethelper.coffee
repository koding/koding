querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateDefaultRequestParams } = require '../index'


generateResetRequestBody = (opts = {}) ->

  defaultBodyObject =
    password      : generateRandomString()
    recoveryToken : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateResetRequestParams = (opts = {}) ->

  token = opts?.body?.email or 'someToken'

  url  = generateUrl
    route : "#{encodeURIComponent token}/Reset"

  body = generateResetRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateResetRequestBody
  generateResetRequestParams
}


