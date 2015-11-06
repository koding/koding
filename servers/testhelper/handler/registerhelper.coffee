{ querystring
  generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'


generateRegisterRequestBody = (opts = {}) ->

  defaultBodyObject =
    _csrf             : generateRandomString()
    email             : generateRandomEmail()
    agree             : 'on'
    username          : generateRandomUsername()
    password          : 'testpass'
    inviteCode        : ''
    passwordConfirm   : 'testpass'

  deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


# overwrites given options in the default params
generateRegisterRequestParams = (opts = {}) ->

  body = generateRegisterRequestBody()

  params =
    url        : generateUrl { route : 'Register' }
    body       : body
    csrfCookie : body._csrf

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateRegisterRequestBody
  generateRegisterRequestParams
}


