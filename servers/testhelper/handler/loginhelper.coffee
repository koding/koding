querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'


generateLoginRequestBody = (opts = {}) ->

  defaultBodyObject =
    _csrf               : generateRandomString()
    token               : ''
    tfcode              : ''
    username            : generateRandomUsername()
    password            : 'testpass'
    redirect            : ''
    groupName           : 'koding'

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


# overwrites given options in the default params
generateLoginRequestParams = (opts = {}) ->

  body = generateLoginRequestBody()

  params =
    url        : generateUrl { route : 'Login' }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateLoginRequestBody
  generateLoginRequestParams
}
