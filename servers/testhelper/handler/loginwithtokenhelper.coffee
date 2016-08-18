{ generateUrl
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateLoginWithTokenRequestParams = (opts = {}) ->

  csrfToken = generateRandomString()

  params =
    qs  : { token : 'token' }
    url : generateUrl { route : '-/loginwithtoken' }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateLoginWithTokenRequestParams
}
