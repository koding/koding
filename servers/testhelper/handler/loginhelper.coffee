querystring = require 'querystring'

{ generateUrl
  deepObjectExtend
  generateRandomUsername
  generateDefaultRequestParams } = require './index'


generateLoginRequestBody = (opts = {}) ->

  defaultBodyObject =
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

  url  = generateUrl
    route : 'Login'

  body = generateLoginRequestBody()

  params                = { url, body }
  defaultRequestParams  = generateDefaultRequestParams params
  requestParams         = deepObjectExtend defaultRequestParams, opts
  # after deep extending object, encodes body param to a query string
  requestParams.body    = querystring.stringify requestParams.body

  return requestParams


module.exports = {
  generateLoginRequestBody
  generateLoginRequestParams
}


