querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateDefaultRequestParams } = require '../index'


generateOptoutRequestBody = (opts = {}) ->

  defaultBodyObject =
    name : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateOptoutRequestParams = (opts = {}) ->

  name = opts?.body?.name or generateRandomString()

  url  = generateUrl
    route : "#{encodeURIComponent name}/Optout"

  body = generateOptoutRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateOptoutRequestBody
  generateOptoutRequestParams
}
