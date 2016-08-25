{ queryString
  generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateRequestBody = (opts = {}) ->

  defaultBodyObject =
    email : ''
    _csrf : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateRequestParams = (opts = {}) ->

  body  = generateRequestBody()

  params =
    url        : generateUrl { route : 'findteam' }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateRequestBody
  generateRequestParams
}
