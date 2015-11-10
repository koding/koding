{ generateUrl
  generateRandomString
  generateRequestParamsEncodeBody } = require './index'


generateGithubCallbackRequestParams = (opts = {}) ->

  csrfToken = generateRandomString()

  params =
    qs         : { _csrf : csrfToken, code : generateRandomString() }
    url        : generateUrl { route : '-/oauth/github/callback' }
    csrfCookie : csrfToken

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateGithubCallbackRequestParams
}
