querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateResetRequestBody = (opts = {}) ->

  defaultBodyObject =
    _csrf         : generateRandomString()
    password      : generateRandomString()
    recoveryToken : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateResetRequestParams = (opts = {}) ->

  token = opts?.body?.email or 'someToken'
  body  = generateResetRequestBody()

  params =
    url        : generateUrl { route : "#{encodeURIComponent token}/Reset" }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateResetRequestBody
  generateResetRequestParams
}
