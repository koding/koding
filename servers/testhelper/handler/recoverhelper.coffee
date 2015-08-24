querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateDefaultRequestParams } = require './index'


defaultExpiryPeriod = 5 * 60 * 1000 # 5 minutes


generateRecoverRequestBody = (opts = {}) ->

  defaultBodyObject =
    email : ''

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateRecoverRequestParams = (opts = {}) ->

  email = opts?.body?.email or generateRandomEmail()

  url  = generateUrl
    route : "#{encodeURIComponent email}/Recover"

  body = generateRecoverRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  defaultExpiryPeriod
  generateRecoverRequestBody
  generateRecoverRequestParams
}


