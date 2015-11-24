{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'


generateImpersonateRequestBody = (opts = {}) ->

  defaultBodyObject = { _csrf : generateRandomString() }
  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateImpersonateRequestParams = (opts = {}) ->

  body     = generateImpersonateRequestBody()
  nickname = opts.nickname ? generateRandomUsername()

  params =
    url        : generateUrl { route : "Impersonate/#{nickname}" }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateImpersonateRequestParams
}
