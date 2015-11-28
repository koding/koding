{ generateUrl
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateConfirmRequestParams = (opts = {}) ->

  csrfToken = generateRandomString()

  params =
    qs  : { token : 'token' }
    url : generateUrl { route : '-/confirm' }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateConfirmRequestParams
}
