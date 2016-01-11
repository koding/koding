{ queryString
  generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


defaultExpiryPeriod = 5 * 60 * 1000 # 5 minutes


generateRecoverRequestBody = (opts = {}) ->

  defaultBodyObject =
    email : ''
    _csrf : generateRandomString()

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateRecoverRequestParams = (opts = {}) ->

  email = opts?.body?.email or generateRandomEmail()
  body  = generateRecoverRequestBody()

  params =
    url        : generateUrl { route : "#{encodeURIComponent email}/Recover" }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  defaultExpiryPeriod
  generateRecoverRequestBody
  generateRecoverRequestParams
}
