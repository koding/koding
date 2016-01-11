{ querystring
  generateUrl
  deepObjectExtend
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateLogoutRequestBody = (opts = {}) ->

  defaultBodyObject =
    name : generateRandomString()
    _csrf : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateLogoutRequestParams = (opts = {}) ->

  name = opts?.body?.name or generateRandomString()
  body = generateLogoutRequestBody()

  params =
    url        : generateUrl { route : "#{encodeURIComponent name}/Logout" }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateLogoutRequestBody
  generateLogoutRequestParams
}
