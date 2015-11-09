{ generateUrl
  generateRandomString
  generateRequestParamsEncodeBody } = require './index'


generateFacebookCallbackRequestParams = (opts = {}) ->

  csrfToken = generateRandomString()

  params =
    qs         : { _csrf : csrfToken, code : generateRandomString() }
    url        : generateUrl { route : '-/oauth/facebook/callback' }
    csrfCookie : csrfToken

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateFacebookCallbackRequestParams
}
