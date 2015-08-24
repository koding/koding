querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomEmail
  generateRandomUsername
  generateDefaultRequestParams } = require '../index'


generateRegisterRequestBody = (opts = {}) ->

  defaultBodyObject =
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

  url  = generateUrl
    route : 'Register'

  body = generateRegisterRequestBody()

  params                = { url, body }
  defaultRequestParams  = generateDefaultRequestParams params
  requestParams         = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body    = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateRegisterRequestBody
  generateRegisterRequestParams
}


