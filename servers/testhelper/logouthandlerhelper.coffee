querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateDefaultRequestParams } = require './index'


generateLogoutRequestBody = (opts = {}) ->

  defaultBodyObject =
    name : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateLogoutRequestParams = (opts = {}) ->

  name = opts?.body?.name or generateRandomString()

  url  = generateUrl
    route : "#{encodeURIComponent name}/Logout"

  body = generateLogoutRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateLogoutRequestBody
  generateLogoutRequestParams
}
