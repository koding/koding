{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRequestParamsEncodeBody } = require './index'


generateOAuthRequestBody = (opts = {}) ->

  defaultBodyObject =
    _csrf          : generateRandomString()
    isUserLoggedIn : 'true'

  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateOAuthRequestParams = (opts = {}) ->

  body = generateOAuthRequestBody()

  params =
    url        : generateUrl { route : 'OAuth' }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateOAuthRequestBody
  generateOAuthRequestParams
}


