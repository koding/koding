querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateDefaultRequestParams } = require '../index'


generateVerifyTokenRequestBody = (opts = {}) ->

  defaultBodyObject =
    token : ''

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateVerifyTokenRequestParams = (opts = {}) ->

  { token } = opts
  delete opts.token

  url  = generateUrl
    route : "Verify/#{token}"

  body = generateVerifyTokenRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateVerifyTokenRequestBody
  generateVerifyTokenRequestParams
}
