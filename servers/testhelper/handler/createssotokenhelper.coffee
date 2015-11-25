{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'


generateCreateSsoTokenRequestBody = (opts = {}) ->

  defaultBodyObject = { username : generateRandomUsername() }
  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateCreateSsoTokenRequestParams = (opts = {}) ->

  params =
    url     : generateUrl { route : "-/api/ssotoken/create" }
    body    : generateCreateSsoTokenRequestBody()
    headers : { Authorization : "Bearer #{generateRandomString()}" }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateCreateSsoTokenRequestParams
}


