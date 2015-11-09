{ generateUrl
  generateRandomString
  generateRequestParamsEncodeBody } = require './index'


generateGoogleCallbackRequestParams = (opts = {}) ->

  csrfToken = generateRandomString()

  params =
    qs         : { _csrf : csrfToken, code : generateRandomString() }
    url        : generateUrl { route : '-/oauth/google/callback' }
    csrfCookie : csrfToken

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateGoogleCallbackRequestParams
}
