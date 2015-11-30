{ generateUrl
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateSsoTokenLoginRequestParams = (opts = {}) ->

  params =
    url     : generateUrl { route : '-/api/ssotoken/login' }
    body    : { token : generateRandomString() }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateSsoTokenLoginRequestParams
}


