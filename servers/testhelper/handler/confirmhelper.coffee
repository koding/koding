{ generateUrl
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateConfirmRequestParams = (opts = {}) ->

  csrfToken = generateRandomString()

  params =
    qs         : { _csrf : csrfToken, token : 'token' }
    url        : generateUrl { route : "-/confirm" }
    csrfCookie : csrfToken

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateConfirmRequestParams
}
