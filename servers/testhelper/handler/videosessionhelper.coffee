{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRequestParamsEncodeBody } = require '../index'


generateVideoSessionRequestBody = (opts = {}) ->

  defaultBodyObject =
    _csrf     : generateRandomString()
    channelId : generateRandomString()

  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateVideoSessionRequestParams = (opts = {}) ->

  body = generateVideoSessionRequestBody()

  params =
    url        : generateUrl { route : '-/video-chat/session' }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateVideoSessionRequestBody
  generateVideoSessionRequestParams
}
