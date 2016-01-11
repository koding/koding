{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateSsoTokenLoginRequestParams = (opts = {}) ->

  params =
    url : generateUrl deepObjectExtend { route : '-/api/ssotoken/login' }, opts.url
    qs  : { token : generateRandomString() }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateSsoTokenLoginRequestParams
}
