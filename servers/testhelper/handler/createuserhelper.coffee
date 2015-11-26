{ generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomString
  generateRandomUsername
  generateRequestParamsEncodeBody } = require '../index'


generateCreateUserRequestBody = (opts = {}) ->

  defaultBodyObject =
    email     : generateRandomEmail()
    username  : generateRandomUsername()
    lastName  : generateRandomString()
    firstName : generateRandomString()

  defaultBodyObject = deepObjectExtend defaultBodyObject, opts

  return defaultBodyObject


generateCreateUserRequestParams = (opts = {}) ->

  body = generateCreateUserRequestBody()

  params =
    url     : generateUrl { route : '-/api/user/create' }
    body    : generateCreateUserRequestBody()
    headers : { Authorization : "Bearer #{generateRandomString()}" }

  requestParams = generateRequestParamsEncodeBody params, opts

  return requestParams


module.exports = {
  generateCreateUserRequestParams
}


