querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateDefaultRequestParams } = require '../index'


generateVerifySlugRequestBody = (opts = {}) ->

  defaultBodyObject =
    name : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateVerifySlugRequestParams = (opts = {}) ->

  url  = generateUrl
    route : '-/teams/verify-domain'

  body = generateVerifySlugRequestBody()

  params               = { url, body }
  defaultRequestParams = generateDefaultRequestParams params
  requestParams        = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body   = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateVerifySlugRequestBody
  generateVerifySlugRequestParams
}
